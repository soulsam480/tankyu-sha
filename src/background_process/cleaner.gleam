import ffi/sqlite
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/otp/actor
import gleam/result
import lib/logger
import models/source_run
import models/task_run

pub type CleanerMessage {
  CheckStaleRuns
}

pub opaque type State {
  State(conn: sqlite.Connection, self: process.Name(CleanerMessage))
}

pub fn new_name() {
  process.new_name("Cleaner")
}

pub fn new(name: process.Name(CleanerMessage), conn: sqlite.Connection) {
  actor.new_with_initialiser(1000, fn(_) {
    let sub = process.named_subject(name)

    let selector = process.new_selector() |> process.select(sub)

    actor.initialised(State(conn:, self: name))
    |> actor.selecting(selector)
    |> Ok
  })
  |> actor.on_message(handle_message)
  |> actor.named(name)
  |> actor.start
}

fn handle_message(state: State, message: CleanerMessage) {
  let State(conn, _self) = state

  let cleaner_logger = logger.new("Cleaner")

  let _ = case message {
    CheckStaleRuns -> {
      logger.info(cleaner_logger, "Checking for stale task and source runs")

      use stale_task_runs <- result.try(
        task_run.pending_in_last_30_minutes(conn)
        |> logger.trap_error(cleaner_logger),
      )

      list.each(stale_task_runs, fn(t_run) {
        let assert Ok(_) =
          t_run
          |> task_run.set_status(task_run.Failure)
          |> task_run.update(conn)
          |> logger.trap_error(cleaner_logger)

        logger.warn(
          cleaner_logger,
          "Marked stale task_run " <> int.to_string(t_run.id) <> " as Failure.",
        )
      })

      // Clean up stale source runs
      use stale_source_runs <- result.try(
        source_run.pending_in_last_30_minutes(conn)
        |> logger.trap_error(cleaner_logger),
      )

      list.each(stale_source_runs, fn(s_run) {
        let assert Ok(_) =
          s_run
          |> source_run.set_status(source_run.Failure)
          |> source_run.update(conn)
          |> logger.trap_error(cleaner_logger)

        logger.warn(
          cleaner_logger,
          "Marked stale source_run "
            <> int.to_string(s_run.id)
            <> " as Failure.",
        )
      })

      logger.info(
        cleaner_logger,
        "Finished checking for stale runs. Task runs: "
          <> int.to_string(list.length(stale_task_runs))
          <> ", Source runs: "
          <> int.to_string(list.length(stale_source_runs)),
      )

      Ok(Nil)
    }
  }

  // Schedule the next run in 15 minutes (900,000 milliseconds)
  process.send_after(process.named_subject(state.self), 900_000, CheckStaleRuns)

  actor.continue(state)
}
