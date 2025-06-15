import argv
import birl
import clip
import clip/help
import clip/opt
import ffi/sqlite
import gleam/dynamic/decode
import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/regexp
import gleam/result
import gleam/string
import justin
import lib/error
import simplifile

pub type Migration {
  Migration(version: String, up: String, down: String)
}

pub type MigrationOp {
  Up
  Down
  Generate(name: String)
}

fn find_files() {
  use priv_dir <- result.try(
    erlang.priv_directory("tankyu_sha")
    |> error.map_to_snag("Unable to get priv dir"),
  )

  use files <- result.try(
    simplifile.get_files(priv_dir <> "/migrations")
    |> error.map_to_snag("Unable to fetch files"),
  )

  Ok(files)
}

fn read_migrations(files: List(String)) {
  list.try_map(files, fn(file) {
    use content <- result.try(
      simplifile.read(file) |> error.map_to_snag("Unable to read file"),
    )

    use re <- result.try(
      regexp.from_string(
        "(?s)-- migrate:up\\s*(.*?)\\s*-- migrate:down\\s*(.*)",
      )
      |> error.map_to_snag("Unable to compile RE"),
    )

    use whitespace_re <- result.try(
      regexp.from_string("(?<!,)\\s{2,}")
      |> error.map_to_snag("Unable to compile RE"),
    )

    use migration_version <- result.try(
      string.split(file, "/")
      |> list.last()
      |> result.map(fn(val) { string.split(val, "_") |> list.first() })
      |> result.flatten
      |> error.map_to_snag("Unable to get migration version"),
    )

    let serialized =
      regexp.split(re, content)
      |> list.filter(fn(it) { !string.is_empty(it) })
      |> list.map(fn(it) {
        string.replace(it, "\n", "") |> regexp.replace(whitespace_re, _, "")
      })

    let assert [up, down, ..] = serialized

    Ok(Migration(version: migration_version, up: up, down: down))
  })
  |> result.map(list.sort(_, fn(a, b) { string.compare(a.version, b.version) }))
}

fn create_schema_table(conn: sqlite.Connection) {
  sqlite.exec(
    conn,
    "CREATE TABLE IF NOT EXISTS \"schema_migrations\" (version varchar(128) primary key);",
    [],
  )
  |> error.map_to_snag("Unable to create schema migrations")
}

type MigrationRow {
  MigrationRow(version: String)
}

fn migration_row_decoder() -> decode.Decoder(MigrationRow) {
  use version <- decode.field("version", decode.string)
  decode.success(MigrationRow(version:))
}

fn select_migrations(conn: sqlite.Connection) {
  use migrations <- result.try(sqlite.query(
    "SELECT version FROM schema_migrations ORDER BY version ASC",
    conn,
    [],
    migration_row_decoder(),
  ))

  Ok(migrations)
}

fn insert_migration(conn: sqlite.Connection, migration: Migration) {
  let assert Ok(_) =
    sqlite.exec(conn, "insert into schema_migrations (version) values (?)", [
      migration.version |> sqlite.bind,
    ])
}

fn delete_migration(conn: sqlite.Connection, migration: Migration) {
  let assert Ok(_) =
    sqlite.exec(conn, "delete from schema_migrations where version = ?", [
      migration.version |> sqlite.bind,
    ])
}

fn run_stmts(stmts: String, with conn: sqlite.Connection) {
  // Split the migration into individual statements
  let statements =
    string.split(stmts, ";")
    |> list.filter(fn(s) { !string.is_empty(string.trim(s)) })
    |> list.map(fn(s) { s <> ";" })

  // Execute each statement
  use _ <- result.try(
    list.try_map(statements, fn(stmt) {
      io.println("Executing: " <> stmt)

      sqlite.exec(conn, stmt, [])
      |> error.map_to_snag("Unable to execute statement")
    }),
  )

  Ok(Nil)
}

fn up_migrate(migration: Migration, with conn: sqlite.Connection) {
  let assert Ok(_) = run_stmts(migration.up, conn)

  let res =
    insert_migration(conn, migration)
    |> error.map_to_snag("Unable to insert migration")
    |> result.replace(Nil)

  case res {
    Ok(_) -> {
      io.println("Migration " <> migration.version <> " has been applied!")
    }
    _ -> {
      Nil
    }
  }

  res
}

fn down_migrate(migration: Migration, with conn: sqlite.Connection) {
  let assert Ok(_) = run_stmts(migration.down, conn)

  let res =
    delete_migration(conn, migration)
    |> error.map_to_snag("Unable to delete migration")
    |> result.replace(Nil)

  case res {
    Ok(_) -> {
      io.println("Migration " <> migration.version <> " has been rolled back!")
    }
    _ -> {
      Nil
    }
  }

  res
}

fn pad_int(val: Int) {
  val
  |> int.to_string
  |> string.pad_start(2, "0")
}

fn generate(name: String) {
  let stamp = birl.utc_now()
  let day = birl.get_day(stamp)
  let time = birl.get_time_of_day(stamp)

  let timestamp =
    [
      day.year |> int.to_string,
      day.month |> pad_int,
      day.date |> pad_int,
      time.hour |> pad_int,
      time.minute |> pad_int,
      time.second |> pad_int,
    ]
    |> list.fold("", fn(acc, curr) { acc <> curr })

  let migration_file_name = timestamp <> "_" <> name |> justin.snake_case

  use priv_dir <- result.try(
    erlang.priv_directory("tankyu_sha")
    |> error.map_to_snag("Unable to get priv dir"),
  )

  let file_path = priv_dir <> "/migrations/" <> migration_file_name <> ".sql"

  use file_exists <- result.try(
    simplifile.is_file(file_path) |> error.map_to_snag("unable to get file"),
  )

  case file_exists {
    True -> {
      io.println("File already exists")

      Ok(Nil)
    }

    False -> {
      io.println("Creating migration file: " <> migration_file_name)

      let _ =
        simplifile.write(
          file_path,
          "-- migrate:up
-- migrate:down",
        )

      Ok(Nil)
    }
  }
}

pub fn run(op: MigrationOp) {
  use conn <- sqlite.with_connection(sqlite.db_path())

  use res <- result.try(
    sqlite.exec(conn, "select sqlite_version(), vec_version()", [])
    |> error.map_to_snag("Unable to query"),
  )

  io.println("Running on " <> { string.inspect(res.rows) })

  use _ <- result.try(create_schema_table(conn))

  use applied_migrations <- result.try(select_migrations(conn))

  use files <- result.try(find_files())

  use migrations <- result.try(read_migrations(files))

  case op {
    Generate(name) -> {
      let _ = generate(name)

      Nil
    }

    Up -> {
      let to_add = case list.length(applied_migrations) {
        0 -> {
          migrations
        }
        _ -> {
          list.filter(migrations, fn(it) {
            list.map(applied_migrations, fn(applied) { applied.version })
            |> list.contains(it.version)
            != True
          })
        }
      }

      case list.length(to_add) {
        0 -> {
          io.println("All migrations have been applied")
        }

        to_add_len -> {
          io.println(
            "Migrations to be applied are: "
            <> to_add_len |> int.to_string
            <> " nos.",
          )

          list.map(to_add, fn(mig) { up_migrate(mig, conn) })

          io.println("All Done!")
        }
      }
    }

    Down -> {
      let to_remove = case list.length(applied_migrations) {
        0 -> {
          []
        }
        _ -> {
          list.filter(migrations, fn(it) {
            list.map(applied_migrations, fn(applied) { applied.version })
            |> list.contains(it.version)
          })
          |> list.reverse
        }
      }

      case list.length(to_remove) {
        0 -> {
          io.println("Rolled back to start!")
        }
        to_remove_len -> {
          io.println(
            "Migrations to be rolled back are: "
            <> int.to_string(to_remove_len)
            <> " nos.",
          )

          list.map(to_remove, fn(mig) { down_migrate(mig, conn) })

          io.println("All Done!")
        }
      }
    }
  }

  Ok(Nil)
}

fn up_command() -> clip.Command(MigrationOp) {
  clip.return(Up)
  |> clip.help(help.simple("up", "Run all migrations"))
}

fn down_command() -> clip.Command(MigrationOp) {
  clip.return(Down)
  |> clip.help(help.simple("down", "Rollback all migrations"))
}

fn generate_command() -> clip.Command(MigrationOp) {
  clip.command({
    use name <- clip.parameter

    Generate(name:)
  })
  |> clip.opt(opt.new("name") |> opt.help("Migration name"))
  |> clip.help(help.simple("new", "Generate a new migration"))
}

fn command() -> clip.Command(MigrationOp) {
  clip.subcommands([
    #("up", up_command()),
    #("down", down_command()),
    #("new", generate_command()),
  ])
}

pub fn main() {
  let result =
    command()
    |> clip.run(argv.load().arguments)

  case result {
    Error(e) -> io.println_error(e)
    Ok(op) -> {
      let _ = run(op)
      Nil
    }
  }
}
