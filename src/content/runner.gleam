import content/feed_source
import content/news_source
import content/search_source
import ffi/sqlite
import gleam/dict
import gleam/int
import gleam/option
import gleam/string
import lib/logger
import models/source
import models/source_run
import snag

pub fn run(
  soc: source.Source,
  run: source_run.SourceRun,
  conn: sqlite.Connection,
) {
  let runner_logger =
    logger.new("SourceRunner")
    |> logger.with_scope(
      dict.from_list([
        #("source.id", int.to_string(soc.id)),
        #("source.kind", string.inspect(soc.kind)),
      ]),
    )

  logger.info(runner_logger, "Running source")

  let run_content = case soc.kind {
    source.Feed -> feed_source.run(soc)
    source.News -> news_source.run(soc)
    source.Search -> search_source.run(soc, conn)
    // NOTE: here a search result can be anything
    // first run it through feed runner, and if it errors, out
    // dumpt it into news
    source.SearchResult -> {
      let feed_resp = feed_source.run(soc)

      case feed_resp {
        Error(_) -> news_source.run(soc)
        _ -> feed_resp
      }
    }
  }

  case soc.kind, run_content {
    source.Search, Ok(_) -> {
      let _ =
        run
        |> source_run.set_status(source_run.ChildrenRunning)
        |> source_run.update(conn)

      logger.info(
        runner_logger,
        "Successfully created child search result sources. They'll run right after.",
      )

      // NOTE: for search, we don't need to return anything,
      // because all synthetic sources will be running right after this
      Ok(Nil)
    }
    _, Ok(res) -> {
      let _ =
        run
        |> source_run.set_content(option.Some(res))
        |> source_run.set_status(source_run.Success)
        |> source_run.update(conn)

      logger.info(runner_logger, "Successfully ran source.")

      Ok(Nil)
    }
    _, _ -> {
      let _ =
        run
        |> source_run.set_status(source_run.Failure)
        |> source_run.update(conn)

      logger.error(runner_logger, "Source run failed to complete")

      Error(snag.new("Failed to run source"))
    }
  }
}
