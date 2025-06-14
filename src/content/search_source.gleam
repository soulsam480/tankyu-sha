import gleam/dict
import gleam/result
import lib/error
import models/source
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

  Ok(Nil)
}

pub fn main() {
  let _ =
    source.new()
    |> source.set_kind(source.Search)
    |> source.set_meta(dict.from_list([#("search_str", "india ai news")]))
    |> run
    |> echo
}
