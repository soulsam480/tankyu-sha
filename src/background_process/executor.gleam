import content/runner
import ffi/sqlite
import gleam/dict
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/option
import gleam/otp/actor
import gleam/result
import gleam/string
import lib/logger
import lib/utils
import models/source
import models/source_run
import models/task_run

type State {
  State(conn: sqlite.Connection, self: process.Subject(ExecutorMessage))
}

pub type ExecutorMessage {
  ExecuteSource(run_id: Int)
  ExecuteTask(task_run_id: Int)
  CompleteTaskExecution(task_run_id: Int)
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
  |> actor.start()
}

fn handle_message(state: State, message: ExecutorMessage) {
  let State(conn, self) = state

  let exec_logger = logger.new("Executor")

  let _ = case message {
    ExecuteTask(run_id) -> {
      logger.info(exec_logger, "Executing task run " <> int.to_string(run_id))

      use task_run <- result.try(task_run.find(run_id, conn))

      let exec_logger =
        exec_logger
        |> logger.with_scope(
          dict.from_list([
            #("task_run.id", int.to_string(run_id)),
            #("task_run.created_at", task_run.created_at),
          ]),
        )

      use sources <- result.try(source.of_task(task_run.task_id, conn))

      let assert Ok(_) =
        task_run
        |> task_run.set_status(task_run.Running)
        |> task_run.update(conn)

      logger.info(
        exec_logger,
        "Found " <> int.to_string(list.length(sources)) <> " sources",
      )

      case utils.list_is_empty(sources) {
        True -> {
          let assert Ok(_) =
            task_run
            |> task_run.set_status(task_run.Success)
            |> task_run.update(conn)

          logger.info(
            exec_logger,
            "Task run completed as no sources were found",
          )

          Nil
        }

        False -> {
          list.each(sources, fn(source) {
            let exec_logger =
              exec_logger
              |> logger.with_scope(
                dict.from_list([
                  #("source.id", int.to_string(source.id)),
                  #("source.kind", string.inspect(source.kind)),
                  #("source.created_at", source.created_at),
                ]),
              )

            logger.info(exec_logger, "Scheduling source run")

            let assert Ok(sour_run) =
              source_run.new()
              |> source_run.set_task_run_id(task_run.id)
              |> source_run.set_source_id(source.id)
              |> source_run.create(conn)

            process.send(self, ExecuteSource(sour_run.id))

            logger.info(
              exec_logger,
              "Scheduled source run with id " <> int.to_string(sour_run.id),
            )
          })
        }
      }

      Ok(Nil)
    }

    ExecuteSource(run_id) -> {
      logger.info(exec_logger, "Executing source run " <> int.to_string(run_id))

      use run <- result.try(source_run.find(run_id, state.conn))

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

      let assert Ok(_) =
        run
        |> source_run.set_status(source_run.Running)
        |> source_run.update(state.conn)

      let _ = runner.run(run, state.conn)

      logger.info(scoped_source_logger, "Source run completed")

      let _ = case run.task_run_id {
        option.Some(run_id) -> {
          logger.info(
            exec_logger,
            "Checking if all associated source runs have completed",
          )

          use runs <- result.try(source_run.pending_of_task_run(
            run.task_run_id,
            conn,
          ))

          case utils.list_is_empty(runs) {
            True -> {
              logger.info(
                exec_logger,
                "All source runs completed. Scheduling parent task run completion.",
              )

              process.send(self, CompleteTaskExecution(run_id))
            }
            False -> {
              logger.info(exec_logger, "Some source runs are still pending.")
            }
          }

          Ok(Nil)
        }
        _ -> {
          logger.info(
            exec_logger,
            "Skipping parent task run checks as it doesn't have any",
          )
          Ok(Nil)
        }
      }
    }

    CompleteTaskExecution(task_run_id) -> {
      use _run <- result.try(task_run.find(task_run_id, state.conn))

      let exec_logger =
        exec_logger
        |> logger.with_scope(
          dict.from_list([#("task_run.id", int.to_string(task_run_id))]),
        )

      logger.info(exec_logger, "Completing task run")

      // TODO: summarize and keep

      Ok(Nil)
    }
  }

  actor.continue(state)
}
