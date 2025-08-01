import background_process/source_run_executor
import ffi/sqlite
import gleam/dict
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/otp/actor
import gleam/result
import gleam/string
import lib/logger
import lib/utils
import lifeguard
import models/source
import models/source_run
import models/task_run

type State {
  State(
    conn: sqlite.Connection,
    source_run_executor_name: process.Name(
      lifeguard.PoolMsg(source_run_executor.ExecutorMessage),
    ),
  )
}

pub type ExecutorMessage {
  ExecuteTask(task_run_id: Int)
}

pub fn new_name() {
  process.new_name("TaskRunExecutor")
}

pub fn new(
  name: process.Name(lifeguard.PoolMsg(ExecutorMessage)),
  conn: sqlite.Connection,
  source_run_executor_name: process.Name(
    lifeguard.PoolMsg(source_run_executor.ExecutorMessage),
  ),
) {
  lifeguard.new_with_initialiser(name, 1000, fn(self) {
    let selector = process.new_selector() |> process.select(self)

    lifeguard.initialised(State(conn:, source_run_executor_name:))
    |> lifeguard.selecting(selector)
    |> Ok
  })
  |> lifeguard.on_message(handle_message)
  |> lifeguard.size(5)
  |> lifeguard.supervised(1000)
}

fn handle_message(state: State, message: ExecutorMessage) {
  let exec_logger = logger.new("Executor")

  let _ = case message {
    ExecuteTask(run_id) -> {
      logger.info(exec_logger, "Executing task run " <> int.to_string(run_id))

      use task_run <- result.try(
        task_run.find(run_id, state.conn) |> logger.trap_error(exec_logger),
      )

      let exec_logger =
        exec_logger
        |> logger.with_scope(
          dict.from_list([
            #("task_run.id", int.to_string(run_id)),
            #("task_run.created_at", task_run.created_at),
          ]),
        )

      use sources <- result.try(
        source.of_task(task_run.task_id, state.conn)
        |> logger.trap_error(exec_logger),
      )

      use task_run <- result.try(
        task_run
        |> task_run.set_status(task_run.Running)
        |> task_run.update(state.conn)
        |> logger.trap_error(exec_logger),
      )

      logger.info(
        exec_logger,
        "Found " <> int.to_string(list.length(sources)) <> " sources",
      )

      let _ = case utils.list_is_empty(sources) {
        True -> {
          use _ <- result.try(
            task_run
            |> task_run.set_status(task_run.Success)
            |> task_run.update(state.conn)
            |> logger.trap_error(exec_logger),
          )

          logger.info(
            exec_logger,
            "Task run completed as no sources were found",
          )

          Ok(Nil)
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

            use sour_run <- result.try(
              source_run.new()
              |> source_run.set_task_run_id(task_run.id)
              |> source_run.set_source_id(source.id)
              |> source_run.set_status(source_run.Queued)
              |> source_run.create(state.conn)
              |> logger.trap_error(exec_logger),
            )

            let _ =
              lifeguard.send(
                process.named_subject(state.source_run_executor_name),
                source_run_executor.ExecuteSource(sour_run.id),
                1000,
              )

            logger.info(
              exec_logger,
              "Scheduled source run with id " <> int.to_string(sour_run.id),
            )

            Ok(Nil)
          })

          Ok(Nil)
        }
      }
    }
  }

  actor.continue(state)
}
