import ffi/sqlite
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/otp/actor
import gleam/result
import lib/logger
import models/document
import models/task_run
import services/config

pub type DocumentCleanerMessage {
  CleanUp
}

pub opaque type State {
  State(conn: sqlite.Connection, self: process.Name(DocumentCleanerMessage))
}

pub fn new_name() {
  process.new_name("document_cleaner")
}

pub fn new(name: process.Name(DocumentCleanerMessage), conn: sqlite.Connection) {
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

fn handle_message(state: State, message: DocumentCleanerMessage) {
  let State(conn, _self) = state

  let cleaner_logger = logger.new("document_cleaner")
  let assert Ok(conf) = config.load()

  let _ = case message {
    CleanUp -> {
      logger.info(cleaner_logger, "Checking for stale documents")

      use task_runs <- result.try(
        task_run.find_before_days(conf.document_expiry_after_days, conn)
        |> logger.trap_notice(cleaner_logger),
      )

      list.each(task_runs, fn(t_run) {
        let assert Ok(_) =
          document.delete_by_task_run_id(t_run.id, conn)
          |> logger.trap_notice(cleaner_logger)

        logger.warn(
          cleaner_logger,
          "Deleted documents for task_run " <> int.to_string(t_run.id),
        )
      })

      logger.info(
        cleaner_logger,
        "Finished checking for stale documents. Task runs: "
          <> int.to_string(list.length(task_runs)),
      )

      Ok(Nil)
    }
  }

  // Schedule the next run in 1 day
  process.send_after(process.named_subject(state.self), 86_400_000, CleanUp)

  actor.continue(state)
}
