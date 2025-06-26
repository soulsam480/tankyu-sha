import background_process/source_run_ingestor
import content/runner
import ffi/sqlite
import gleam/dict
import gleam/erlang/process
import gleam/int
import gleam/otp/actor
import gleam/result
import gleam/string
import lib/logger
import lifeguard
import models/source_run

type State {
  State(
    conn: sqlite.Connection,
    source_run_ingestor_name: process.Name(
      lifeguard.PoolMsg(source_run_ingestor.IngestorMessage),
    ),
  )
}

pub type ExecutorMessage {
  ExecuteSource(run_id: Int)
}

pub fn new_name() {
  process.new_name("SourceRunExecutor")
}

pub fn new(
  name: process.Name(lifeguard.PoolMsg(ExecutorMessage)),
  conn: sqlite.Connection,
  source_run_ingestor_name: process.Name(
    lifeguard.PoolMsg(source_run_ingestor.IngestorMessage),
  ),
) {
  lifeguard.new_with_initialiser(name, 1000, fn(self) {
    let selector = process.new_selector() |> process.select(self)

    lifeguard.initialised(State(conn:, source_run_ingestor_name:))
    |> lifeguard.selecting(selector)
    |> Ok
  })
  |> lifeguard.on_message(handle_message)
  |> lifeguard.size(10)
  |> lifeguard.supervised(1000)
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

      let _ =
        lifeguard.send(
          process.named_subject(state.source_run_ingestor_name),
          source_run_ingestor.SourceRun(run_id),
          1000,
        )

      Ok(Nil)
    }
  }

  actor.continue(state)
}
