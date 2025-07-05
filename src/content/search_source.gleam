import ffi/sqlite
import gleam/dict
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import lib/error
import lib/logger
import models/source
import services/config
import services/internet_search

pub fn run(source: source.Source, conn: sqlite.Connection) {
  let browser_logger = logger.new("SearchRunner")

  use search_descr <- result.try(
    dict.get(source.meta, "search_str") |> error.map_to_snag(""),
  )

  use conf <- result.try(config.load())

  use results <- result.try(
    internet_search.ddg(search_descr, [
      // TODO: allow config from task via source meta
      internet_search.Pages("1"),
      internet_search.Range(conf.ddg_result_range),
    ])
    // NOTE: take first 5 for now as search is super taxing on compute
    |> result.map(list.take(_, conf.max_search_source_results)),
  )

  logger.info(
    browser_logger,
    "Creating sources from "
      <> int.to_string(list.length(results))
      <> " results",
  )

  list.filter(results, fn(res) { option.is_some(res.link) })
  |> list.each(fn(res) {
    source.new()
    |> source.set_url(option.unwrap(res.link, ""))
    |> source.set_task_id(option.unwrap(source.task_id, -1))
    |> source.set_kind(source.SearchResult)
    |> source.set_meta(
      dict.from_list([
        #("title", res.title),
        #("description", res.description),
        #("published_at", res.published_at |> option.unwrap("")),
        #("publisher", res.publisher |> option.unwrap("")),
      ]),
    )
    |> source.create(conn)
  })

  Ok("")
}
