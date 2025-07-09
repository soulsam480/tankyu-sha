import background_process/source_run_ingestor
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
import lifeguard
import models/source
import models/source_run

type State {
  State(
    self: process.Name(lifeguard.PoolMsg(ExecutorMessage)),
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

    lifeguard.initialised(State(conn:, self: name, source_run_ingestor_name:))
    |> lifeguard.selecting(selector)
    |> Ok
  })
  |> lifeguard.on_message(handle_message)
  |> lifeguard.size(5)
  |> lifeguard.supervised(1000)
}

fn handle_message(state: State, message: ExecutorMessage) {
  let exec_logger = logger.new("SourceRunExecutor")

  let _ = case message {
    ExecuteSource(run_id) -> {
      logger.info(exec_logger, "Executing source run " <> int.to_string(run_id))

      use run <- result.try(
        source_run.find(run_id, state.conn) |> logger.trap_error(exec_logger),
      )

      let scoped_source_logger =
        exec_logger
        |> logger.with_scope(
          dict.from_list([
            #("source_run.id", int.to_string(run.source_id)),
            #("source_run.source_id", string.inspect(run.source_id)),
            #("source_run.created_at", run.created_at),
            #("source_run.set_task_run_id", string.inspect(run.task_run_id)),
          ]),
        )

      use run <- result.try(
        run
        |> source_run.set_status(source_run.Running)
        |> source_run.update(state.conn)
        |> logger.trap_error(exec_logger),
      )

      use soc <- result.try(source.find(run.source_id, state.conn))

      let _ = runner.run(soc, run, state.conn)

      case soc.kind {
        // NOTE: for search source, we need to create and queue source runs from here
        source.Search -> {
          use search_res_sources <- result.try(source.search_result_of_task(
            option.unwrap(soc.task_id, -1),
            state.conn,
          ))

          case utils.list_is_empty(search_res_sources) {
            True -> {
              Ok(Nil)
            }
            _ -> {
              list.each(search_res_sources, fn(source) {
                let exec_logger =
                  logger.new("SourceRunExecutor")
                  |> logger.with_scope(
                    dict.from_list([
                      #("source.parent_source_id", int.to_string(soc.id)),
                      #("source.id", int.to_string(source.id)),
                      #("source.kind", string.inspect(source.kind)),
                      #("source.created_at", source.created_at),
                    ]),
                  )

                logger.info(exec_logger, "Scheduling source run")

                use sour_run <- result.try(
                  source_run.new()
                  |> source_run.set_task_run_id(option.unwrap(
                    run.task_run_id,
                    -1,
                  ))
                  |> source_run.set_source_id(source.id)
                  |> source_run.set_status(source_run.Queued)
                  |> source_run.create(state.conn)
                  |> logger.trap_error(exec_logger),
                )

                let _ =
                  lifeguard.send(
                    process.named_subject(state.self),
                    ExecuteSource(sour_run.id),
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
        _ -> {
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
    }
  }

  actor.continue(state)
}
