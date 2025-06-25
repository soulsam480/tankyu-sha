import background_process/lib/source_meta
import ffi/ai
import ffi/sqlite
import gleam/dict
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/option
import gleam/otp/actor
import gleam/result
import gleam/string_tree
import lib/logger
import models/source
import models/source_run
import models/task_run

pub type IngestorMessage {
  TaskRun(run_id: Int)
}

pub opaque type State {
  State(conn: sqlite.Connection, self: process.Subject(IngestorMessage))
}

pub fn new(conn: sqlite.Connection) {
  actor.new_with_initialiser(1000, fn(self) {
    let selector = process.new_selector() |> process.select(self)

    actor.initialised(State(conn:, self:))
    |> actor.selecting(selector)
    |> actor.returning(self)
    |> Ok
  })
  |> actor.on_message(handle_message)
  |> actor.start
}

fn handle_message(state: State, message: IngestorMessage) {
  let State(conn, _self) = state

  let ingest_logger = logger.new("TaskRunIngestor")

  let _ = case message {
    TaskRun(run_id) -> {
      use task_run <- result.try(
        task_run.find(run_id, conn) |> logger.trap_notice(ingest_logger),
      )

      use task_run <- result.try(
        task_run
        |> task_run.set_status(task_run.Embedding)
        |> task_run.update(conn)
        |> logger.trap_notice(ingest_logger),
      )

      let ingest_logger =
        ingest_logger
        |> logger.with_scope(
          dict.from_list([#("task_run.id", int.to_string(run_id))]),
        )

      use source_runs <- result.try(source_run.successful_of_task_run(
        option.Some(run_id),
        conn,
      ))

      let context =
        string_tree.new()
        |> string_tree.append(
          "Following are content extracted from various sources. The metadata is accompanied below.\n\n",
        )
        |> list.index_fold(source_runs, _, fn(acc, source_run, index) {
          let assert Ok(source) = source.find(source_run.source_id, conn)

          source_meta.prepare_source_meta(acc, source_run, source, index)
          |> string_tree.append(option.unwrap(source_run.summary, "") <> "\n\n")
        })
        |> string_tree.append(
          "\n\n You need to summarize these summaries of content collection from various resources.",
        )
        |> string_tree.to_string

      use summary <- result.try(
        ai.analyse(ai.ContentAnalysis, context)
        |> logger.trap_notice(ingest_logger),
      )

      use _ <- result.try(
        task_run
        |> task_run.set_content(summary)
        |> task_run.set_status(task_run.Success)
        |> task_run.update(conn)
        |> logger.trap_notice(ingest_logger),
      )

      Ok(Nil)
    }
  }

  actor.continue(state)
}
