import chrobot
import content/source
import gleam/list
import gleam/result
import lib/error
import services/browser

pub fn run(source: source.Source) {
  use browser, page <- browser.load(source.url)

  use _ <- result.try(
    chrobot.await_load_event(browser, page) |> error.map_to_snag(""),
  )

  use _ <- result.try(
    chrobot.await_selector(page, ".updates__list") |> error.map_to_snag(""),
  )

  use results <- result.try(
    chrobot.select_all(page, ".updates__list") |> error.map_to_snag(""),
  )

  let _value =
    list.map(results, fn(it) { chrobot.get_text(page, it) })
    |> result.all()
    |> echo

  Ok(Nil)
}
