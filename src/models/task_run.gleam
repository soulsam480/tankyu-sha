import birl
import ffi/sqlite
import gleam/dynamic/decode
import gleam/list
import gleam/option.{type Option}
import gleam/result
import lib/error

pub opaque type TaskRun {
  TaskRun(
    id: Int,
    task_id: Int,
    digest_id: Option(Int),
    status: String,
    content: String,
    created_at: String,
    updated_at: String,
  )
}

fn task_run_decoder() -> decode.Decoder(TaskRun) {
  use id <- decode.field("id", decode.int)
  use task_id <- decode.optional_field("task_id", 0, decode.int)
  use digest_id <- decode.optional_field(
    "digest_id",
    option.None,
    decode.optional(decode.int),
  )
  use status <- decode.optional_field("status", "pending", decode.string)
  use content <- decode.optional_field("content", "", decode.string)
  use created_at <- decode.optional_field("created_at", "", decode.string)
  use updated_at <- decode.optional_field("updated_at", "", decode.string)

  decode.success(TaskRun(
    id:,
    task_id:,
    digest_id:,
    status:,
    content:,
    created_at:,
    updated_at:,
  ))
}

pub fn new() {
  TaskRun(
    id: 0,
    task_id: 0,
    digest_id: option.None,
    status: "pending",
    content: "",
    created_at: birl.utc_now() |> birl.to_iso8601(),
    updated_at: birl.utc_now() |> birl.to_iso8601(),
  )
}

pub fn set_status(task_run: TaskRun, status: String) {
  TaskRun(..task_run, status:)
}

pub fn set_content(task_run: TaskRun, content: String) {
  TaskRun(..task_run, content:)
}

pub fn set_digest_id(task_run: TaskRun, digest_id: Int) {
  TaskRun(..task_run, digest_id: option.Some(digest_id))
}

pub fn create(task_run: TaskRun, connection: sqlite.Connection) {
  let res =
    sqlite.exec(
      connection,
      "INSERT INTO task_runs (task_id, digest_id, status, content, created_at, updated_at) 
       VALUES (?, ?, ?, ?, ?, ?)",
      [
        task_run.task_id |> sqlite.bind,
        task_run.digest_id |> sqlite.option,
        task_run.status |> sqlite.bind,
        task_run.content |> sqlite.bind,
        task_run.created_at |> sqlite.bind,
        task_run.updated_at |> sqlite.bind,
      ],
    )

  result.is_ok(res)
}

pub fn find(id: Int, conn: sqlite.Connection) {
  use items <- result.try(sqlite.query(
    "SELECT id, task_id, digest_id, status, content, created_at, updated_at 
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

pub fn update(task_run: TaskRun, conn: sqlite.Connection) {
  let res =
    sqlite.exec(
      conn,
      "UPDATE task_runs 
       SET status = ?, 
           content = ?, 
           digest_id = ?, 
           updated_at = ? 
       WHERE id = ?",
      [
        task_run.status |> sqlite.bind,
        task_run.content |> sqlite.bind,
        task_run.digest_id |> sqlite.option,
        birl.utc_now() |> birl.to_iso8601() |> sqlite.bind,
        task_run.id |> sqlite.bind,
      ],
    )

  result.is_ok(res)
}

pub fn of_task(task_id: Int, conn: sqlite.Connection) {
  use items <- result.try(sqlite.query(
    "SELECT id, task_id, digest_id, status, content, created_at, updated_at 
     FROM task_runs 
     WHERE task_id = ?
     ORDER BY created_at DESC;",
    conn,
    [task_id |> sqlite.bind],
    task_run_decoder(),
  ))

  Ok(items)
}
