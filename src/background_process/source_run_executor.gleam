import background_process/ingestor
import content/runner
import ffi/sqlite
import gleam/dict
import gleam/erlang/process
import gleam/int
import gleam/otp/actor
import gleam/result
import gleam/string
import lib/logger
import models/source_run

type State {
  State(
    conn: sqlite.Connection,
    ingestor_sub: process.Subject(ingestor.IngestorMessage),
    self: process.Subject(ExecutorMessage),
  )
}

pub type ExecutorMessage {
  ExecuteSource(run_id: Int)
}

pub fn new(
  conn: sqlite.Connection,
  ingestor_sub: process.Subject(ingestor.IngestorMessage),
) {
  actor.new_with_initialiser(1000, fn(self) {
    let selector = process.new_selector() |> process.select(self)

    actor.initialised(State(conn:, ingestor_sub:, self:))
    |> actor.selecting(selector)
    |> actor.returning(self)
    |> Ok
  })
  |> actor.on_message(handle_message)
  |> actor.start()
}

fn handle_message(state: State, message: ExecutorMessage) {
  let exec_logger = logger.new("Executor")

  let _ = case message {
    ExecuteSource(run_id) -> {
      logger.info(exec_logger, "Executing source run " <> int.to_string(run_id))

      use run <- result.try(
        source_run.find(run_id, state.conn) |> logger.trap_notice(exec_logger),
      )

      let scoped_source_logger =
        exec_logger
        |> logger.with_scope(
          dict.from_list([
            #("source_run.id", int.to_string(run.source_id)),
            #("source_run.kind", string.inspect(run.source_id)),
            #("source_run.created_at", run.created_at),
            #("source_run.set_task_run_id", string.inspect(run.task_run_id)),
          ]),
        )

      use run <- result.try(
        run
        |> source_run.set_status(source_run.Running)
        |> source_run.update(state.conn)
        |> logger.trap_notice(exec_logger),
      )

      let _ = runner.run(run, state.conn)

      logger.info(
        scoped_source_logger,
        "Source run completed. Scheduling ingestion.",
      )

      process.send(state.ingestor_sub, ingestor.SourceRun(run_id))

      Ok(Nil)
    }
  }

  actor.continue(state)
}
