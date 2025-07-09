import background_process/lib/source_meta
import background_process/task_run_ingestor
import ffi/ai
import ffi/llmchain
import ffi/sqlite
import gleam/dict
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/option
import gleam/otp/actor
import gleam/result
import gleam/string_tree
import lib/error
import lib/logger
import lib/utils
import lifeguard
import models/document
import models/source
import models/source_run
import services/config

type Ingestable {
  Ingestable(index: Int, doc: String)
}

pub type IngestorMessage {
  SourceRun(run_id: Int)
}

pub opaque type State {
  State(
    conn: sqlite.Connection,
    task_run_ingestor_name: process.Name(
      lifeguard.PoolMsg(task_run_ingestor.IngestorMessage),
    ),
  )
}

pub fn new_name() {
  process.new_name("SourceRunIngestor")
}

pub fn new(
  name: process.Name(lifeguard.PoolMsg(IngestorMessage)),
  conn: sqlite.Connection,
  task_run_ingestor_name: process.Name(
    lifeguard.PoolMsg(task_run_ingestor.IngestorMessage),
  ),
) {
  let assert Ok(conf) = config.load()

  lifeguard.new_with_initialiser(name, 1000, fn(self) {
    let selector = process.new_selector() |> process.select(self)

    lifeguard.initialised(State(conn:, task_run_ingestor_name:))
    |> lifeguard.selecting(selector)
    |> Ok
  })
  |> lifeguard.on_message(handle_message)
  // WARN: this is super taxing on the machine, dial up when more ram
  |> lifeguard.size(conf.ingestor_actor_pool_count)
  |> lifeguard.supervised(1000)
}

fn handle_message(state: State, message: IngestorMessage) {
  let State(conn, task_run_ingestor_name) = state

  let ingest_logger = logger.new("SourceRunIngestor")

  let _ = case message {
    SourceRun(run_id) -> {
      use source_run <- result.try(
        source_run.find(run_id, conn) |> logger.trap_error(ingest_logger),
      )

      let ingest_logger =
        ingest_logger
        |> logger.with_scope(
          dict.from_list([#("source_run.id", int.to_string(run_id))]),
        )

      logger.info(ingest_logger, "Ingesting source run")

      use source <- result.try(
        source.find(source_run.source_id, conn)
        |> logger.trap_error(ingest_logger),
      )

      use source_run <- result.try(
        source_run
        |> source_run.set_status(source_run.Embedding)
        |> source_run.update(conn)
        |> logger.trap_error(ingest_logger),
      )

      case source_run.content {
        option.Some(content) -> {
          let context =
            string_tree.new()
            |> source_meta.prepare_source_meta(source_run, source, 0)
            |> string_tree.append(option.unwrap(source_run.content, ""))
            |> string_tree.to_string

          use summary <- result.try(
            ai.analyse(ai.ContentAnalysis, context)
            |> logger.trap_error(ingest_logger),
          )

          logger.info(ingest_logger, "Done analysing run. Updating run data")

          use source_run <- result.try(
            source_run
            |> source_run.set_summary(option.Some(summary))
            |> source_run.update(conn)
            |> logger.trap_error(ingest_logger),
          )

          logger.info(ingest_logger, "Begin embedding")

          let chunks =
            llmchain.split_text(content, option.None, option.None)
            |> list.index_map(fn(it, index) { Ingestable(index, it) })

          logger.info(
            ingest_logger,
            "Generated " <> int.to_string(list.length(chunks)) <> " chunks",
          )

          use res <- result.try(
            ai.embed(chunks |> list.map(fn(it) { it.doc }))
            |> error.map_to_snag("invalid embed")
            |> logger.trap_error(ingest_logger),
          )

          use embeds <- result.try(
            ai.pluck_embedding(res)
            |> logger.trap_error(ingest_logger),
          )

          let _ =
            list.index_map(embeds, fn(it_embed, index) {
              use doc <- result.try(
                list.find(chunks, fn(it_chunk) { it_chunk.index == index })
                |> logger.trap_error(ingest_logger),
              )

              use _ <- result.try(
                document.new()
                |> document.set_source_run_id(run_id)
                |> document.set_content(doc.doc)
                |> document.set_content_embedding(it_embed)
                |> document.create(conn)
                |> logger.trap_error(ingest_logger)
                |> result.replace_error(Nil),
              )

              Ok(Nil)
            })

          logger.info(
            ingest_logger,
            "Successfully embedded and stored source run content.",
          )

          use source_run <- result.try(
            source_run
            |> source_run.set_status(source_run.Success)
            // NOTE: we're nullifying the original content so that ingested docuements become the single source of truth
            |> source_run.set_content(option.None)
            |> source_run.update(conn)
            |> logger.trap_error(ingest_logger),
          )

          case source_run.task_run_id {
            option.Some(run_id) -> {
              logger.info(
                ingest_logger,
                "Checking if all associated source runs have completed",
              )

              use runs <- result.try(
                source_run.pending_of_task_run(source_run.task_run_id, conn)
                |> logger.trap_error(ingest_logger),
              )

              let _ = case utils.list_is_empty(runs) {
                True -> {
                  let _ =
                    lifeguard.send(
                      process.named_subject(task_run_ingestor_name),
                      task_run_ingestor.TaskRun(run_id),
                      1000,
                    )

                  logger.info(
                    ingest_logger,
                    "All source runs completed. Scheduled parent task for ingestion.",
                  )

                  Ok(Nil)
                }
                False -> {
                  use first_run <- result.try(
                    list.first(runs) |> error.map_to_snag("empty"),
                  )

                  case list.length(runs), first_run.status {
                    1, source_run.ChildrenRunning -> {
                      let _ =
                        source_run.set_status(first_run, source_run.Success)
                        |> source_run.update(conn)
                        |> logger.trap_error(ingest_logger)

                      let _ =
                        lifeguard.send(
                          process.named_subject(task_run_ingestor_name),
                          task_run_ingestor.TaskRun(run_id),
                          1000,
                        )
                        |> logger.trap_error(ingest_logger)

                      logger.info(
                        ingest_logger,
                        "All source runs completed. Scheduled parent task for ingestion.",
                      )
                    }
                    _, _ -> {
                      logger.info(
                        ingest_logger,
                        "Some source runs are still pending.",
                      )
                    }
                  }

                  Ok(Nil)
                }
              }

              Ok(Nil)
            }
            _ -> {
              Ok(Nil)
            }
          }
        }

        option.None -> {
          logger.info(
            ingest_logger,
            "Source run content is empty. Skipping embedding.",
          )

          Ok(Nil)
        }
      }
    }
  }

  actor.continue(state)
}
