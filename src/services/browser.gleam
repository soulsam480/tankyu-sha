import gleam/list
import gleam/otp/task
import gleam/result
import gleam/string
import lib/error
import shellout
import snag

type BrowserError(a) {
  ShellError(a)
  TaskError(a)
}

pub fn load(
  url url: String,
  with opts: List(String),
) -> Result(String, snag.Snag) {
  let browser_task = task.async(do_load(url, opts))

  task.await_forever(browser_task)
  |> result.map_error(fn(e) { TaskError(e |> string.inspect) })
  |> error.map_to_snag("Browser load error")
}

fn do_load(url: String, opts: List(String)) {
  fn() {
    shellout.command(
      "node",
      ["./priv/run.mjs", url] |> list.append(opts),
      ".",
      [],
    )
    |> result.map_error(fn(e) { ShellError(e |> string.inspect) })
  }
}

pub fn main() {
  load("https://www.linkedin.com/company/revenuehero", ["LinkedIn"]) |> echo
}
