import birl
import ffi/sqlite
import gleam/dynamic/decode
import gleam/list
import gleam/option.{type Option}
import gleam/result
import lib/error

pub opaque type SourceRun {
  SourceRun(
    id: Int,
    status: String,
    created_at: String,
    updated_at: String,
    source_id: Int,
    digest_id: Option(Int),
    task_run_id: Option(Int),
  )
}

fn source_run_decoder() -> decode.Decoder(SourceRun) {
  use id <- decode.field("id", decode.int)
  use status <- decode.optional_field("status", "pending", decode.string)
  use created_at <- decode.optional_field("created_at", "", decode.string)
  use updated_at <- decode.optional_field("updated_at", "", decode.string)
  use source_id <- decode.optional_field("source_id", 0, decode.int)

  use digest_id <- decode.optional_field(
    "digest_id",
    option.None,
    decode.optional(decode.int),
  )

  use task_run_id <- decode.optional_field(
    "task_run_id",
    option.None,
    decode.optional(decode.int),
  )

  decode.success(SourceRun(
    id:,
    status:,
    created_at:,
    updated_at:,
    source_id:,
    digest_id:,
    task_run_id:,
  ))
}

pub fn new() {
  SourceRun(
    id: 0,
    status: "pending",
    created_at: birl.utc_now() |> birl.to_iso8601(),
    updated_at: birl.utc_now() |> birl.to_iso8601(),
    source_id: 0,
    digest_id: option.None,
    task_run_id: option.None,
  )
}

pub fn set_status(source_run: SourceRun, status: String) {
  SourceRun(..source_run, status:)
}

pub fn set_digest_id(source_run: SourceRun, digest_id: Int) {
  SourceRun(..source_run, digest_id: option.Some(digest_id))
}

pub fn set_task_run_id(source_run: SourceRun, task_run_id: Int) {
  SourceRun(..source_run, task_run_id: option.Some(task_run_id))
}

pub fn create(source_run: SourceRun, connection: sqlite.Connection) {
  use res <- result.try(
    sqlite.exec(
      connection,
      "INSERT INTO source_runs (status, created_at, updated_at, source_id, digest_id, task_run_id) 
       VALUES (?, ?, ?, ?, ?, ?)
       RETURNING id;",
      [
        source_run.status |> sqlite.bind,
        source_run.created_at |> sqlite.bind,
        source_run.updated_at |> sqlite.bind,
        source_run.source_id |> sqlite.bind,
        source_run.digest_id |> sqlite.option,
        source_run.task_run_id |> sqlite.option,
      ],
    ),
  )

  use id <- result.try(sqlite.get_inserted_id(res))

  Ok(SourceRun(..source_run, id:))
}

pub fn find(id: Int, conn: sqlite.Connection) {
  use items <- result.try(sqlite.query(
    "SELECT id, status, created_at, updated_at, source_id, digest_id, task_run_id 
     FROM source_runs 
     WHERE id = ?;",
    conn,
    [id |> sqlite.bind],
    source_run_decoder(),
  ))

  use first <- result.try(
    list.first(items) |> error.map_to_snag("Invalid result"),
  )

  Ok(first)
}

pub fn update(source_run: SourceRun, conn: sqlite.Connection) {
  let res =
    sqlite.exec(
      conn,
      "UPDATE source_runs 
       SET status = ?, 
           digest_id = ?, 
           task_run_id = ?, 
           updated_at = ? 
       WHERE id = ?",
      [
        source_run.status |> sqlite.bind,
        source_run.digest_id |> sqlite.option,
        source_run.task_run_id |> sqlite.option,
        birl.utc_now() |> birl.to_iso8601() |> sqlite.bind,
        source_run.id |> sqlite.bind,
      ],
    )

  result.is_ok(res)
}

pub fn of_source(source_id: Int, conn: sqlite.Connection) {
  use items <- result.try(sqlite.query(
    "SELECT id, status, created_at, updated_at, source_id, digest_id, task_run_id 
     FROM source_runs 
     WHERE source_id = ?
     ORDER BY created_at DESC;",
    conn,
    [source_id |> sqlite.bind],
    source_run_decoder(),
  ))

  Ok(items)
}
