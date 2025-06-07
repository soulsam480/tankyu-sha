import gleam/dict
import gleam/dynamic
import gleam/dynamic/decode
import gleam/list
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

// pub type SqliteError {
//   DecodeError
//   ExecError
//   InvalidResponse
// }

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
pub fn exec(
  conn: Connection,
  query: String,
  params: List(Value),
) -> Result(dict.Dict(ResultKey, List(dynamic.Dynamic)), String)

pub fn query(
  sql: String,
  on connection: Connection,
  with arguments: List(Value),
  expecting decoder: decode.Decoder(t),
) -> Result(List(t), snag.Snag) {
  use response <- result.try(
    exec(connection, sql, arguments)
    |> error.map_to_snag("ExecError"),
  )

  use rows <- result.try(
    dict.get(response, Rows)
    |> error.map_to_snag("InvalidResponse"),
  )

  use outcome <- result.try(
    list.try_map(rows, fn(it) { decode.run(it, decoder) })
    |> error.map_to_snag("DecodeError"),
  )

  Ok(outcome)
}

@external(erlang, "Elixir.Sqlite", "bind")
pub fn int(val: Int) -> Value

@external(erlang, "Elixir.Sqlite", "bind")
pub fn float(val: Float) -> Value

pub fn bool(val: Bool) -> Value {
  case val {
    True -> 1
    False -> 0
  }
  |> int
}

@external(erlang, "Elixir.Sqlite", "bind")
pub fn string(val: String) -> Value

@external(erlang, "Elixir.Sqlite", "bind_null")
pub fn null() -> Value

pub fn decode_bool() -> decode.Decoder(Bool) {
  use b <- decode.then(decode.int)

  case b {
    0 -> decode.success(False)
    _ -> decode.success(True)
  }
}
