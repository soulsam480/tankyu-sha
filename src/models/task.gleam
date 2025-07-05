import birl
import ffi/sqlite
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option}
import gleam/result
import lib/error
import snag

pub type Task {
  Task(
    id: Int,
    topic: String,
    active: Bool,
    schedule: String,
    last_run_at: Option(String),
    delivery_route: String,
    created_at: String,
    updated_at: String,
  )
}

fn task_decoder() -> decode.Decoder(Task) {
  use id <- decode.field("id", decode.int)
  use topic <- decode.optional_field("topic", "", decode.string)
  use active <- decode.optional_field("active", True, sqlite.decode_bool())
  use schedule <- decode.optional_field("schedule", "", decode.string)

  use last_run_at <- decode.optional_field(
    "last_run_at",
    option.None,
    decode.optional(decode.string),
  )

  use delivery_route <- decode.optional_field(
    "delivery_route",
    "",
    decode.string,
  )

  use created_at <- decode.optional_field("created_at", "", decode.string)
  use updated_at <- decode.optional_field("updated_at", "", decode.string)

  decode.success(Task(
    id:,
    topic:,
    active:,
    schedule:,
    last_run_at:,
    delivery_route:,
    created_at:,
    updated_at:,
  ))
}

pub fn new() {
  Task(
    id: 0,
    topic: "",
    active: True,
    schedule: "",
    last_run_at: option.None,
    delivery_route: "",
    created_at: birl.utc_now() |> birl.to_iso8601(),
    updated_at: birl.utc_now() |> birl.to_iso8601(),
  )
}

pub fn set_topic(task: Task, topic: String) {
  Task(..task, topic:)
}

pub fn set_active(task: Task, active: Bool) {
  Task(..task, active:)
}

pub fn set_schedule(task: Task, schedule: String) {
  Task(..task, schedule:)
}

pub fn set_last_run_at(task: Task, last_run_at: String) {
  Task(..task, last_run_at: option.Some(last_run_at))
}

pub fn set_delivery_route(task: Task, delivery_route: String) {
  Task(..task, delivery_route:)
}

pub fn create(task: Task, connection: sqlite.Connection) {
  use res <- result.try(
    sqlite.exec(
      connection,
      "INSERT INTO tasks (topic, active, schedule, delivery_route, created_at, updated_at) 
       VALUES (?, ?, ?, ?, ?, ?)
       RETURNING id;",
      [
        task.topic |> sqlite.bind,
        task.active |> sqlite.bool,
        task.schedule |> sqlite.bind,
        task.delivery_route |> sqlite.bind,
        task.created_at |> sqlite.bind,
        task.updated_at |> sqlite.bind,
      ],
    ),
  )

  use id <- result.try(sqlite.get_inserted_id(res))

  Ok(Task(..task, id:))
}

pub fn find(id: Int, conn: sqlite.Connection) {
  use items <- result.try(sqlite.query(
    "SELECT id, topic, active, schedule, last_run_at, delivery_route, created_at, updated_at 
     FROM tasks 
     WHERE id = ?;",
    conn,
    [id |> sqlite.bind],
    task_decoder(),
  ))

  use first <- result.try(
    list.first(items) |> error.map_to_snag("Invalid result"),
  )

  Ok(first)
}

pub fn update(task: Task, conn: sqlite.Connection) {
  sqlite.exec(
    conn,
    "UPDATE tasks 
       SET topic = ?, 
           active = ?, 
           schedule = ?, 
           delivery_route = ?,
           last_run_at = ?
       WHERE id = ?",
    [
      task.topic |> sqlite.bind,
      task.active |> sqlite.bool,
      task.schedule |> sqlite.bind,
      task.delivery_route |> sqlite.bind,
      task.last_run_at |> sqlite.option,
      task.id |> sqlite.bind,
    ],
  )
}

pub fn active_batch(
  conn: sqlite.Connection,
  cb: fn(List(Task)) -> Result(a, snag.Snag),
) -> Result(a, snag.Snag) {
  do_active_batch_recursive(conn, cb, 1)
}

fn do_active_batch_recursive(
  conn: sqlite.Connection,
  cb: fn(List(Task)) -> Result(a, snag.Snag),
  page: Int,
) -> Result(a, snag.Snag) {
  let limit = 10
  let offset = { page - 1 } * limit

  use items <- result.try(sqlite.query(
    "SELECT id, topic, active, schedule, last_run_at, delivery_route, created_at, updated_at 
    FROM tasks 
    LIMIT ? OFFSET ?;",
    conn,
    [limit |> sqlite.bind, offset |> sqlite.bind],
    task_decoder(),
  ))

  case items {
    [] -> cb([])

    val -> {
      use _ <- result.try(cb(val))

      do_active_batch_recursive(conn, cb, page + 1)
    }
  }
}

pub fn destroy(task: Task, connection: sqlite.Connection) {
  sqlite.exec(connection, "DELETE FROM tasks WHERE id = ?;", [
    task.id |> sqlite.bind,
  ])
}

pub fn all_with_pagination(connection: sqlite.Connection, page: Int) {
  let limit = 10

  let offset = { page - 1 } * limit

  use items <- result.try(sqlite.query(
    "SELECT id, topic, active, schedule, last_run_at, delivery_route, created_at, updated_at 
    FROM tasks 
    LIMIT ? OFFSET ?;",
    connection,
    [limit |> sqlite.bind, offset |> sqlite.bind],
    task_decoder(),
  ))

  Ok(items)
}

pub fn all(connection: sqlite.Connection) {
  use items <- result.try(sqlite.query(
    "SELECT id, topic, active, schedule, last_run_at, delivery_route, created_at, updated_at
     FROM tasks;",
    connection,
    [],
    task_decoder(),
  ))

  Ok(items)
}

pub fn to_json(t: Task) -> json.Json {
  json.object([
    #("id", json.int(t.id)),
    #("topic", json.string(t.topic)),
    #("active", json.bool(t.active)),
    #("schedule", json.string(t.schedule)),
    #("delivery_route", json.string(t.delivery_route)),
    #("created_at", json.string(t.created_at)),
    #("updated_at", json.string(t.updated_at)),
  ])
}
