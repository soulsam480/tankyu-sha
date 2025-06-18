import birl
import birl/duration
import ffi/sqlite
import gleam/dynamic/decode
import gleam/list
import gleam/result
import lib/error

pub type Task {
  Task(
    id: Int,
    topic: String,
    active: Bool,
    delivery_at: String,
    delivery_route: String,
    created_at: String,
    updated_at: String,
  )
}

fn task_decoder() -> decode.Decoder(Task) {
  use id <- decode.field("id", decode.int)
  use topic <- decode.optional_field("topic", "", decode.string)
  use active <- decode.optional_field("active", True, sqlite.decode_bool())
  use delivery_at <- decode.optional_field("delivery_at", "", decode.string)

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
    delivery_at:,
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
    delivery_at: "",
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

pub fn set_delivery_at(task: Task, delivery_at: String) {
  Task(..task, delivery_at:)
}

pub fn set_delivery_route(task: Task, delivery_route: String) {
  Task(..task, delivery_route:)
}

pub fn create(task: Task, connection: sqlite.Connection) {
  use res <- result.try(
    sqlite.exec(
      connection,
      "INSERT INTO tasks (topic, active, delivery_at, delivery_route, created_at, updated_at) 
       VALUES (?, ?, ?, ?, ?, ?)
       RETURNING id;",
      [
        task.topic |> sqlite.bind,
        task.active |> sqlite.bool,
        task.delivery_at |> sqlite.bind,
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
    "SELECT id, topic, active, delivery_at, delivery_route, created_at, updated_at 
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
  let res =
    sqlite.exec(
      conn,
      "UPDATE tasks 
       SET topic = ?, 
           active = ?, 
           delivery_at = ?, 
           delivery_route = ?, 
           updated_at = ? 
       WHERE id = ?",
      [
        task.topic |> sqlite.bind,
        task.active |> sqlite.bool,
        task.delivery_at |> sqlite.bind,
        task.delivery_route |> sqlite.bind,
        birl.utc_now() |> birl.to_iso8601() |> sqlite.bind,
        task.id |> sqlite.bind,
      ],
    )

  result.is_ok(res)
}

pub fn active(conn: sqlite.Connection) {
  use items <- result.try(sqlite.query(
    "SELECT id, topic, active, delivery_at, delivery_route, created_at, updated_at 
     FROM tasks 
     WHERE active = 1
     ORDER BY delivery_at ASC;",
    conn,
    [],
    task_decoder(),
  ))

  Ok(items)
}

pub fn in_next_5_hours(conn: sqlite.Connection) {
  use items <- result.try(sqlite.query(
    "SELECT id, topic, active, delivery_at, delivery_route, created_at, updated_at 
     FROM tasks 
     WHERE active = 1 AND date(delivery_at) BETWEEN date(?) AND date(?)
     ORDER BY delivery_at ASC;",
    conn,
    [
      birl.utc_now() |> birl.to_iso8601() |> sqlite.bind,
      birl.utc_now()
        |> birl.add(duration.hours(5))
        |> birl.to_iso8601()
        |> sqlite.bind,
    ],
    task_decoder(),
  ))

  Ok(items)
}
