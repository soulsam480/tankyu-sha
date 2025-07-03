import content/feed_source
import content/news_source
import content/search_source
import ffi/sqlite
import gleam/dict
import gleam/int
import gleam/option
import gleam/result
import gleam/string
import lib/logger
import models/source
import models/source_run
import snag

pub fn run(run: source_run.SourceRun, conn: sqlite.Connection) {
  use soc <- result.try(source.find(run.source_id, conn))

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
    source.Search -> search_source.run(soc)
    // TODO:
    source.SearchResult -> Ok("")
  }

  case run_content {
    Ok(res) -> {
      let _ =
        run
        |> source_run.set_content(option.Some(res))
        |> source_run.set_status(source_run.Success)
        |> source_run.update(conn)

      logger.info(runner_logger, "Successfully ran source.")

      Ok(Nil)
    }
    _ -> {
      let _ =
        run
        |> source_run.set_status(source_run.Failure)
        |> source_run.update(conn)

      logger.notice(runner_logger, "Source run failed to complete")

      Error(snag.new("Failed to run source"))
    }
  }
}
