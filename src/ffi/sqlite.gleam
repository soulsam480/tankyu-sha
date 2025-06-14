import envoy
import gleam/dynamic
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option}
import gleam/result
import lib/error
import snag

pub type Value

pub type Connection {
  Connection(dynamic: dynamic.Dynamic)
}

pub type ResultKey {
  Columns
  Rows
  NumRows
}

pub type ExecResult {
  ExecResult(columns: List(String), rows: List(dynamic.Dynamic), num_rows: Int)
}

fn exec_result_decoder() -> decode.Decoder(ExecResult) {
  use columns <- decode.optional_field(Columns, [], decode.list(decode.string))
  use rows <- decode.optional_field(Rows, [], decode.list(decode.dynamic))
  use num_rows <- decode.optional_field(NumRows, -1, decode.int)

  decode.success(ExecResult(columns:, rows:, num_rows:))
}

@external(erlang, "Elixir.Sqlite", "open")
pub fn open(path: String) -> Result(Connection, String)

pub fn with_connection(path: String, cb: fn(Connection) -> a) -> a {
  let assert Ok(connection) = open(path)
  let value = cb(connection)
  let assert Ok(_) = close(connection)
  value
}

@external(erlang, "Elixir.Sqlite", "close")
pub fn close(conn: Connection) -> Result(Nil, String)

@external(erlang, "Elixir.Sqlite", "exec")
fn exec_(
  conn: Connection,
  query: String,
  params: List(Value),
) -> Result(dynamic.Dynamic, String)

pub fn exec(conn: Connection, query: String, params: List(Value)) {
  use val <- result.try(
    exec_(conn, query, params)
    |> error.map_to_snag("ExecError"),
  )

  use res <- result.try(
    decode.run(val, exec_result_decoder())
    |> error.map_to_snag("Unable to decode base result"),
  )

  Ok(res)
}

@external(erlang, "Elixir.Sqlite", "zip")
fn zip(columns: List(String), rows: dynamic.Dynamic) -> dynamic.Dynamic

pub fn query(
  sql: String,
  on connection: Connection,
  with arguments: List(Value),
  expecting decoder: decode.Decoder(t),
) -> Result(List(t), snag.Snag) {
  use response <- result.try(exec(connection, sql, arguments))

  use outcome <- result.try(
    list.try_map(response.rows, fn(it) {
      decode.run(zip(response.columns, it), decoder)
    })
    |> error.map_to_snag("DecodeError"),
  )

  Ok(outcome)
}

// NOTE: bind a gleam type to sqlite type

@external(erlang, "Elixir.Sqlite", "bind")
pub fn bind(val: a) -> Value

@external(erlang, "Elixir.Sqlite", "bind_nil")
pub fn null() -> Value

pub fn bool(val: Bool) -> Value {
  case val {
    True -> 1
    False -> 0
  }
  |> bind
}

pub fn vec(of: List(Float)) {
  of
  |> json.array(json.float)
  |> json.to_string
  |> bind
}

pub fn option(val: Option(a)) {
  case val {
    option.Some(internal) -> bind(internal)
    _ -> null()
  }
}

pub fn decode_bool() -> decode.Decoder(Bool) {
  use b <- decode.then(decode.int)

  case b {
    0 -> decode.success(False)
    _ -> decode.success(True)
  }
}

pub fn db_path() {
  let env = envoy.get("APP_ENV") |> result.unwrap("development")
  env <> ".sqlite3"
}
