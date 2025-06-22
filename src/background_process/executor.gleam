import background_process/ingestor
import content/runner
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
import models/source
import models/source_run
import models/task_run

type State {
  State(
    conn: sqlite.Connection,
    ingestor_sub: process.Subject(ingestor.IngestorMessage),
    self: process.Subject(ExecutorMessage),
  )
}

pub type ExecutorMessage {
  ExecuteSource(run_id: Int)
  ExecuteTask(task_run_id: Int)
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
  let State(conn, ingestor_sup, self) = state

  let exec_logger = logger.new("Executor")

  let _ = case message {
    ExecuteTask(run_id) -> {
      logger.info(exec_logger, "Executing task run " <> int.to_string(run_id))

      use task_run <- result.try(
        task_run.find(run_id, conn) |> logger.trap_notice(exec_logger),
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
        source.of_task(task_run.task_id, conn)
        |> logger.trap_notice(exec_logger),
      )

      use _ <- result.try(
        task_run
        |> task_run.set_status(task_run.Running)
        |> task_run.update(conn)
        |> logger.trap_notice(exec_logger),
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
            |> task_run.update(conn)
            |> logger.trap_notice(exec_logger),
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
              |> source_run.create(conn)
              |> logger.trap_notice(exec_logger),
            )

            process.send(self, ExecuteSource(sour_run.id))

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

      use _ <- result.try(
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

      process.send(ingestor_sup, ingestor.SourceRun(run_id))

      Ok(Nil)
    }
  }

  actor.continue(state)
}
