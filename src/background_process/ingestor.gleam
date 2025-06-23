import birl
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
import gleam/string
import gleam/string_tree
import lib/error
import lib/logger
import lib/utils
import models/document
import models/source
import models/source_run
import models/task_run

type Ingestable {
  Ingestable(index: Int, doc: String)
}

pub type IngestorMessage {
  TaskRun(run_id: Int)
  SourceRun(run_id: Int)
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
  let State(conn, self) = state

  let ingest_logger = logger.new("Ingestor")

  let _ = case message {
    TaskRun(run_id) -> {
      use task_run <- result.try(
        task_run.find(run_id, conn) |> logger.trap_notice(ingest_logger),
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

          prepare_source_meta(acc, source_run, source, index)
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

    SourceRun(run_id) -> {
      use source_run <- result.try(
        source_run.find(run_id, conn) |> logger.trap_notice(ingest_logger),
      )

      let ingest_logger =
        ingest_logger
        |> logger.with_scope(
          dict.from_list([#("source_run.id", int.to_string(run_id))]),
        )

      logger.info(
        ingest_logger,
        "Ingesting source run" <> int.to_string(run_id),
      )

      use source <- result.try(
        source.find(source_run.source_id, conn)
        |> logger.trap_notice(ingest_logger),
      )

      use source_run <- result.try(
        source_run
        |> source_run.set_status(source_run.Embedding)
        |> source_run.update(conn)
        |> logger.trap_notice(ingest_logger),
      )

      case source_run.content {
        option.Some(content) -> {
          let context =
            prepare_source_meta(string_tree.new(), source_run, source, 0)
            |> string_tree.append(option.unwrap(source_run.content, ""))
            |> string_tree.to_string

          use summary <- result.try(
            ai.analyse(ai.ContentAnalysis, context)
            |> logger.trap_notice(ingest_logger),
          )

          logger.info(ingest_logger, "Done analysing run. Updating run data")

          use source_run <- result.try(
            source_run
            |> source_run.set_summary(option.Some(summary))
            |> source_run.update(conn)
            |> logger.trap_notice(ingest_logger),
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
            ai.embed(chunks |> list.map(fn(it) { it.doc }), option.None)
            |> error.map_to_snag("invalid embed")
            |> logger.trap_notice(ingest_logger),
          )

          use embeds <- result.try(
            ai.pluck_embedding(res)
            |> logger.trap_notice(ingest_logger),
          )

          let _ =
            list.index_map(embeds, fn(it_embed, index) {
              use doc <- result.try(
                list.find(chunks, fn(it_chunk) { it_chunk.index == index })
                |> logger.trap_notice(ingest_logger),
              )

              use _ <- result.try(
                document.new()
                |> document.set_source_run_id(run_id)
                |> document.set_content(doc.doc)
                |> document.set_content_embedding(it_embed)
                |> document.create(conn)
                |> logger.trap_notice(ingest_logger)
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
            |> source_run.update(conn)
            |> logger.trap_notice(ingest_logger),
          )

          schedule_task_completion(source_run, conn, self, ingest_logger)
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

fn schedule_task_completion(
  run: source_run.SourceRun,
  conn: sqlite.Connection,
  self: process.Subject(IngestorMessage),
  ingest_logger: logger.Logger,
) {
  case run.task_run_id {
    option.Some(run_id) -> {
      logger.info(
        ingest_logger,
        "Checking if all associated source runs have completed",
      )

      use runs <- result.try(
        source_run.pending_of_task_run(run.task_run_id, conn)
        |> logger.trap_notice(ingest_logger),
      )

      case utils.list_is_empty(runs) {
        True -> {
          process.send(self, TaskRun(run_id))

          logger.info(
            ingest_logger,
            "All source runs completed. Scheduled parent task for ingestion.",
          )
        }
        False -> {
          logger.info(ingest_logger, "Some source runs are still pending.")
        }
      }

      Ok(Nil)
    }
    _ -> {
      Ok(Nil)
    }
  }
}

fn prepare_source_meta(
  tree: string_tree.StringTree,
  source_run: source_run.SourceRun,
  source: source.Source,
  index: Int,
) {
  string_tree.append(
    tree,
    int.to_string(index + 1)
      <> ". Extracted from "
      <> source.url
      <> ". "
      <> "The source is of type "
      <> string.inspect(source.kind)
      <> ". "
      <> "The data was collected at "
      <> {
      birl.parse(source_run.updated_at)
      |> result.unwrap(birl.now())
      |> birl.to_naive
    }
      <> "."
      <> "\n",
  )
}
