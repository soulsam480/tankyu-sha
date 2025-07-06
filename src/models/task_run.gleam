import birl
import ffi/sqlite
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import lib/error
import snag

pub type TaskRunStatus {
  Queued
  Running
  Failure
  Success
  Embedding
}

pub type TaskRun {
  TaskRun(
    id: Int,
    task_id: Int,
    status: TaskRunStatus,
    content: String,
    created_at: String,
    updated_at: String,
  )
}

fn task_run_decoder() -> decode.Decoder(TaskRun) {
  use id <- decode.field("id", decode.int)
  use task_id <- decode.optional_field("task_id", 0, decode.int)

  use status <- decode.optional_field(
    "status",
    Queued,
    decode.string |> decode.map(task_status_decoder),
  )

  use content <- decode.optional_field("content", "", decode.string)
  use created_at <- decode.optional_field("created_at", "", decode.string)
  use updated_at <- decode.optional_field("updated_at", "", decode.string)

  decode.success(TaskRun(
    id:,
    task_id:,
    status:,
    content:,
    created_at:,
    updated_at:,
  ))
}

fn task_status_decoder(status: String) {
  case status {
    "pending" -> Queued
    "running" -> Running
    "failure" -> Failure
    "success" -> Success
    "embedding" -> Embedding
    _ -> Queued
  }
}

fn task_status_encoder(task_status: TaskRunStatus) -> String {
  case task_status {
    Queued -> "queued"
    Running -> "running"
    Failure -> "failure"
    Success -> "success"
    Embedding -> "embedding"
  }
}

pub fn new() {
  TaskRun(
    id: 0,
    task_id: 0,
    status: Queued,
    content: "",
    created_at: birl.utc_now() |> birl.to_iso8601(),
    updated_at: birl.utc_now() |> birl.to_iso8601(),
  )
}

pub fn set_status(task_run: TaskRun, status: TaskRunStatus) {
  TaskRun(..task_run, status:)
}

pub fn set_content(task_run: TaskRun, content: String) {
  TaskRun(..task_run, content:)
}

pub fn set_task_id(task_run: TaskRun, task_id: Int) {
  TaskRun(..task_run, task_id:)
}

pub fn create(task_run: TaskRun, connection: sqlite.Connection) {
  use res <- result.try(
    sqlite.exec(
      connection,
      "INSERT INTO task_runs (task_id, status, content, created_at, updated_at) 
       VALUES (?, ?, ?, ?, ?)
       RETURNING id;",
      [
        task_run.task_id |> sqlite.bind,
        task_run.status |> task_status_encoder |> sqlite.bind,
        task_run.content |> sqlite.bind,
        task_run.created_at |> sqlite.bind,
        task_run.updated_at |> sqlite.bind,
      ],
    ),
  )

  use id <- result.try(sqlite.get_inserted_id(res))

  Ok(TaskRun(..task_run, id:))
}

pub fn find(id: Int, conn: sqlite.Connection) {
  use items <- result.try(sqlite.query(
    "SELECT id, task_id, status, content, created_at, updated_at 
     FROM task_runs 
     WHERE id = ?;",
    conn,
    [id |> sqlite.bind],
    task_run_decoder(),
  ))

  use first <- result.try(
    list.first(items) |> error.map_to_snag("Invalid result"),
  )

  Ok(first)
}

/// Loads all task runs with pagination.
///
/// Args:
///   page_number: The desired page number (1-indexed).
///   page_size: The maximum number of items to return per page.
///   conn: The database connection.
///
/// Returns:
///   A Result containing a list of TaskRun records or a Snag if an error occurs.
pub fn all(
  page_number: Int,
  page_size: Int,
  conn: sqlite.Connection,
) -> Result(List(TaskRun), snag.Snag) {
  // Ensure page_number is at least 1, as pagination is typically 1-indexed.
  let safe_page_number = int.max(1, page_number)

  let offset = { safe_page_number - 1 } * page_size
  let limit = page_size

  sqlite.query(
    "SELECT id, task_id, status, content, created_at, updated_at
     FROM task_runs
     LIMIT ? OFFSET ?;",
    conn,
    [limit |> sqlite.bind, offset |> sqlite.bind],
    task_run_decoder(),
  )
}

pub fn update(task_run: TaskRun, conn: sqlite.Connection) {
  use _ <- result.try(
    sqlite.exec(
      conn,
      "UPDATE task_runs 
       SET status = ?, 
           content = ?,
           task_id = ?,
           updated_at = ? 
       WHERE id = ?",
      [
        task_run.status |> task_status_encoder |> sqlite.bind,
        task_run.content |> sqlite.bind,
        task_run.task_id |> sqlite.bind,
        birl.utc_now() |> birl.to_iso8601() |> sqlite.bind,
        task_run.id |> sqlite.bind,
      ],
    ),
  )

  Ok(task_run)
}

pub fn of_task(task_id: Int, conn: sqlite.Connection) {
  use items <- result.try(sqlite.query(
    "SELECT id, task_id, status, content, created_at, updated_at 
     FROM task_runs 
     WHERE task_id = ?
     ORDER BY created_at DESC;",
    conn,
    [task_id |> sqlite.bind],
    task_run_decoder(),
  ))

  Ok(items)
}

pub fn pending_in_last_30_minutes(conn: sqlite.Connection) {
  use items <- result.try(sqlite.query(
    "SELECT id, task_id, status, content, created_at, updated_at
     FROM task_runs
     WHERE (status = ? OR status = ?) AND updated_at >= DATETIME('now', '-30 minutes');",
    conn,
    [
      Running |> task_status_encoder |> sqlite.bind,
      Embedding |> task_status_encoder |> sqlite.bind,
    ],
    task_run_decoder(),
  ))

  Ok(items)
}

pub fn find_before_days(days: Int, conn: sqlite.Connection) {
  let days_string = int.to_string(days)

  let query = "SELECT id, task_id, status, content, created_at, updated_at
     FROM task_runs
     WHERE updated_at <= DATETIME('now', '-" <> days_string <> " days');"

  use items <- result.try(sqlite.query(query, conn, [], task_run_decoder()))

  Ok(items)
}

pub fn to_json(t: TaskRun) -> json.Json {
  json.object([
    #("id", json.int(t.id)),
    #("task_id", json.int(t.task_id)),
    #("status", json.string(t.status |> task_status_encoder)),
    #("content", json.string(t.content)),
    #("created_at", json.string(t.created_at)),
    #("updated_at", json.string(t.updated_at)),
  ])
}
