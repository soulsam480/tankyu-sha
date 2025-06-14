import ffi/sqlite
import gleam/dynamic/decode
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn test_open_and_close_test() {
  let conn = sqlite.open(":memory:") |> should.be_ok()
  sqlite.close(conn) |> should.be_ok()
}

pub fn exec_insert_and_query_test() {
  let conn = sqlite.open(":memory:") |> should.be_ok()

  sqlite.exec(
    conn,
    "CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, age INTEGER, guest BOOLEAN)",
    [],
  )
  |> should.be_ok()

  sqlite.exec(conn, "INSERT INTO users (name, age, guest) VALUES (?, ?, ?)", [
    sqlite.bind("John"),
    sqlite.bind(25),
    sqlite.bool(False),
  ])
  |> should.be_ok()

  sqlite.exec(conn, "INSERT INTO users (name, age, guest) VALUES (?, ?, ?)", [
    sqlite.bind("Jane"),
    sqlite.bind(30),
    sqlite.bool(True),
  ])
  |> should.be_ok()

  sqlite.query("SELECT * FROM users", conn, [], user_decoder())
  |> should.be_ok()
  |> should.equal([User(1, "John", 25, False), User(2, "Jane", 30, True)])

  sqlite.close(conn) |> should.be_ok()
}

type User {
  User(id: Int, name: String, age: Int, guest: Bool)
}

fn user_decoder() -> decode.Decoder(User) {
  use id <- decode.field("id", decode.int)
  use name <- decode.optional_field("name", "", decode.string)
  use age <- decode.optional_field("age", -1, decode.int)
  use guest <- decode.optional_field("guest", False, sqlite.decode_bool())

  decode.success(User(id:, name:, age:, guest:))
}
