import ffi/sqlite
import gleam/dict
import gleam/list
import gleam/result
import lib/error
import models/source
import models/task
import services/internet_search

pub fn run(source: source.Source) {
  use search_descr <- result.try(
    dict.get(source.meta, "search_str") |> error.map_to_snag(""),
  )

  use results <- result.try(
    internet_search.ddg(search_descr, [
      internet_search.Pages("3"),
      internet_search.Range("d"),
    ]),
  )

  echo results

  Ok("")
}

pub fn main() {
  use conn <- sqlite.with_connection(sqlite.db_path())

  let _ = task.new() |> task.create(conn) |> echo

  let assert Ok(ts) = task.active(conn)

  let soc =
    source.new()
    |> source.set_kind(source.Search)
    |> source.set_task_id({ list.first(ts) |> result.unwrap(task.new()) }.id)
    |> source.set_url("")
    |> source.set_meta(dict.from_list([#("search_str", "india ai news")]))

  let _ = soc |> source.create(conn) |> echo

  soc
  |> run
  |> echo
}
