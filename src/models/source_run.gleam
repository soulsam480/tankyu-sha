import birl
import ffi/sqlite
import gleam/dynamic/decode
import gleam/list
import gleam/option.{type Option}
import gleam/result
import lib/error

pub type SourceRunStatus {
  Queued
  Running
  ChildrenRunning
  Failure
  Success
  Embedding
}

pub type SourceRun {
  SourceRun(
    id: Int,
    content: Option(String),
    summary: Option(String),
    status: SourceRunStatus,
    created_at: String,
    updated_at: String,
    source_id: Int,
    task_run_id: Option(Int),
  )
}

fn source_run_decoder() -> decode.Decoder(SourceRun) {
  use id <- decode.field("id", decode.int)
  use content <- decode.optional_field(
    "content",
    option.None,
    decode.optional(decode.string),
  )

  use summary <- decode.optional_field(
    "summary",
    option.None,
    decode.optional(decode.string),
  )

  use status <- decode.optional_field(
    "status",
    Queued,
    decode.string |> decode.map(source_run_status_decoder),
  )

  use created_at <- decode.optional_field("created_at", "", decode.string)
  use updated_at <- decode.optional_field("updated_at", "", decode.string)
  use source_id <- decode.optional_field("source_id", 0, decode.int)

  use task_run_id <- decode.optional_field(
    "task_run_id",
    option.None,
    decode.optional(decode.int),
  )

  decode.success(SourceRun(
    id:,
    content:,
    summary:,
    status:,
    created_at:,
    updated_at:,
    source_id:,
    task_run_id:,
  ))
}

fn source_run_status_decoder(status: String) {
  case status {
    "pending" -> Queued
    "running" -> Running
    "failure" -> Failure
    "success" -> Success
    "embedding" -> Embedding
    "children_running" -> ChildrenRunning
    _ -> Queued
  }
}

fn source_run_status_encoder(task_status: SourceRunStatus) -> String {
  case task_status {
    Queued -> "queued"
    ChildrenRunning -> "children_running"
    Running -> "running"
    Failure -> "failure"
    Success -> "success"
    Embedding -> "embedding"
  }
}

pub fn new() {
  SourceRun(
    id: 0,
    content: option.None,
    summary: option.None,
    status: Queued,
    created_at: birl.utc_now() |> birl.to_iso8601(),
    updated_at: birl.utc_now() |> birl.to_iso8601(),
    source_id: 0,
    task_run_id: option.None,
  )
}

pub fn set_status(source_run: SourceRun, status: SourceRunStatus) {
  SourceRun(..source_run, status:)
}

pub fn set_task_run_id(source_run: SourceRun, task_run_id: Int) {
  SourceRun(..source_run, task_run_id: option.Some(task_run_id))
}

pub fn set_source_id(source_run: SourceRun, source_id: Int) -> SourceRun {
  SourceRun(..source_run, source_id:)
}

pub fn set_summary(
  source_run: SourceRun,
  summary: option.Option(String),
) -> SourceRun {
  SourceRun(..source_run, summary:)
}

pub fn set_content(
  source_run: SourceRun,
  content: option.Option(String),
) -> SourceRun {
  SourceRun(..source_run, content:)
}

pub fn create(source_run: SourceRun, connection: sqlite.Connection) {
  use res <- result.try(
    sqlite.exec(
      connection,
      "INSERT INTO source_runs (status, content, summary, created_at, updated_at, source_id, task_run_id) 
       VALUES (?, ?, ?, ?, ?, ?, ?)
       RETURNING id;",
      [
        source_run.status |> source_run_status_encoder |> sqlite.bind,
        source_run.content |> sqlite.option,
        source_run.summary |> sqlite.option,
        source_run.created_at |> sqlite.bind,
        source_run.updated_at |> sqlite.bind,
        source_run.source_id |> sqlite.bind,
        source_run.task_run_id |> sqlite.option,
      ],
    ),
  )

  use id <- result.try(sqlite.get_inserted_id(res))

  Ok(SourceRun(..source_run, id:))
}

pub fn find(id: Int, conn: sqlite.Connection) {
  use items <- result.try(sqlite.query(
    "SELECT id, content, summary, status, created_at, updated_at, source_id, task_run_id 
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
  use _ <- result.try(
    sqlite.exec(
      conn,
      "UPDATE source_runs 
       SET status = ?, 
           content = ?, 
           summary = ?, 
           task_run_id = ?, 
           updated_at = ? 
       WHERE id = ?",
      [
        source_run.status |> source_run_status_encoder |> sqlite.bind,
        source_run.content |> sqlite.option,
        source_run.summary |> sqlite.option,
        source_run.task_run_id |> sqlite.option,
        birl.utc_now() |> birl.to_iso8601() |> sqlite.bind,
        source_run.id |> sqlite.bind,
      ],
    ),
  )

  Ok(source_run)
}

pub fn of_source(source_id: Int, conn: sqlite.Connection) {
  use items <- result.try(sqlite.query(
    "SELECT id, content, summary, status, created_at, updated_at, source_id, task_run_id 
     FROM source_runs 
     WHERE source_id = ?
     ORDER BY created_at DESC;",
    conn,
    [source_id |> sqlite.bind],
    source_run_decoder(),
  ))

  Ok(items)
}

pub fn pending_of_task_run(
  task_run_id: option.Option(Int),
  conn: sqlite.Connection,
) {
  use items <- result.try(sqlite.query(
    "SELECT id, content, summary, status, created_at, updated_at, source_id, task_run_id 
     FROM source_runs 
     WHERE task_run_id = ? AND status NOT IN (?, ?);",
    conn,
    [
      task_run_id |> sqlite.option,
      Success |> source_run_status_encoder |> sqlite.bind,
      Failure |> source_run_status_encoder |> sqlite.bind,
    ],
    source_run_decoder(),
  ))

  Ok(items)
}

pub fn successful_of_task_run(
  task_run_id: option.Option(Int),
  conn: sqlite.Connection,
) {
  use items <- result.try(sqlite.query(
    "SELECT id, content, summary, status, created_at, updated_at, source_id, task_run_id 
     FROM source_runs 
     WHERE task_run_id = ? AND status = ?;",
    conn,
    [
      task_run_id |> sqlite.option,
      Success |> source_run_status_encoder |> sqlite.bind,
    ],
    source_run_decoder(),
  ))

  Ok(items)
}

pub fn pending_in_last_30_minutes(conn: sqlite.Connection) {
  use items <- result.try(sqlite.query(
    "SELECT id, content, summary, status, created_at, updated_at, source_id, task_run_id
     FROM source_runs
     WHERE (status = ? OR status = ?) AND updated_at >= DATETIME('now', '-30 minutes');",
    conn,
    [
      Running |> source_run_status_encoder |> sqlite.bind,
      Embedding |> source_run_status_encoder |> sqlite.bind,
    ],
    source_run_decoder(),
  ))

  Ok(items)
}
