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
  let command_opt = {
    case list.find(opts, fn(it) { string.contains(it, "--debug=true") }) {
      Ok(_) -> [shellout.LetBeStderr, shellout.LetBeStdout]
      _ -> []
    }
  }

  fn() {
    shellout.command(
      "node",
      ["./priv/run.mjs", "--url=" <> url] |> list.append(opts),
      ".",
      command_opt,
    )
    |> result.map_error(fn(e) { ShellError(e |> string.inspect) })
  }
}
