import gleam/dynamic
import gleam/dynamic/decode
import gleam/json
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

pub fn load_raw(
  url url: String,
  with opts: List(String),
) -> Result(String, snag.Snag) {
  let browser_task = task.async(do_load(url, opts))

  task.await_forever(browser_task)
  |> result.map_error(fn(e) { TaskError(e |> string.inspect) })
  |> error.map_to_snag("Browser load error")
}

pub fn load(
  url url: String,
  with opts: List(String),
) -> Result(BrowserResponse, snag.Snag) {
  use response <- result.try(load_raw(url, opts))

  use base_response <- result.try(
    decode_base_result(response)
    |> error.map_to_snag("Browser returned invalid response"),
  )

  Ok(base_response)
}

fn do_load(url: String, opts: List(String)) {
  let has_debug = list.find(opts, fn(it) { string.contains(it, "--debug") })

  let command_opt = {
    case has_debug {
      Ok(_) -> [shellout.LetBeStderr, shellout.LetBeStdout]
      _ -> []
    }
  }

  let arguments = {
    let base = ["priv/run.mjs", "--url=" <> url] |> list.append(opts)

    case has_debug {
      Ok(_) -> base |> list.prepend("--inspect")
      _ -> base
    }
  }

  fn() {
    shellout.command("node", arguments, ".", command_opt)
    |> result.map_error(fn(e) { ShellError(e |> string.inspect) })
  }
}

pub type BrowserResponse {
  SuccessResponse(data: dynamic.Dynamic)
  ErrorResponse(error: dynamic.Dynamic)
}

fn decode_base_result(json_str: String) {
  let success_decoder = {
    use data <- decode.field("data", decode.dynamic)
    decode.success(SuccessResponse(data:))
  }

  let error_decoder = {
    use data <- decode.field("error", decode.dynamic)
    decode.success(ErrorResponse(error: data))
  }

  json.parse(json_str, decode.one_of(success_decoder, [error_decoder]))
}
