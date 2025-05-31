import content/source
import gleam/dict
import gleam/result
import lib/error
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
    run(source.Source(
      source.Search,
      "",
      dict.from_list([#("search_str", "india ai news")]),
    ))
    |> echo
}
