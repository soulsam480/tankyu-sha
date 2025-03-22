import chrobot
import chrobot/chrome
import gleam/io
import gleam/list
import gleam/result

pub fn main() {
  let config =
    chrome.BrowserConfig(
      path: "/Applications/Chromium.app/Contents/MacOS/Chromium",
      args: chrome.get_default_chrome_args()
        |> list.filter(fn(x) { x != "--headless" })
        |> list.append(["--user-data-dir=/tmp/chromium-debug"]),
      log_level: chrome.LogLevelInfo,
      start_timeout: chrome.default_timeout,
    )

  use browser <- result.map(chrome.launch_with_config(config))
  use page <- result.map(chrobot.open(
    browser,
    "https://duckduckgo.com/?q=som",
    30_000,
  ))
  use _ <- result.map(chrobot.await_load_event(browser, page))
  use page_items <- result.map(chrobot.select_all(page, "a"))

  use title_results <- result.map(
    list.map(page_items, fn(i) { chrobot.get_attribute(page, i, "href") })
    |> result.all(),
  )

  io.debug(title_results)

  use _ <- result.try(chrobot.quit(browser))

  Ok(Nil)
}
