import envoy
import gleam/dynamic
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import gleam/string_tree
import gleam/uri
import lib/error
import lib/logger
import shellout
import snag

pub fn load_raw(
  url url: String,
  with opts: List(String),
) -> Result(String, snag.Snag) {
  do_load(url, opts) |> error.map_to_snag("Browser load error")
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
  let browser_logger = logger.new("Browser")

  start_service(browser_logger)

  let params =
    list.fold(
      opts,
      string_tree.from_string("url=" <> uri.percent_encode(url)),
      fn(acc, curr) { acc |> string_tree.append("&" <> curr) },
    )
    |> string_tree.to_string

  use req <- result.try(
    make_servive_req("/api/process?" <> params)
    |> error.map_to_snag("Unable to make request"),
  )

  use resp <- result.try(
    httpc.send(req) |> error.map_to_snag("Unable to send request"),
  )

  Ok(resp.body)
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

fn make_servive_req(path: String) {
  let port = envoy.get("BROWSER_SERVICE_PORT") |> result.unwrap("3005")
  let url = "http://localhost:" <> port <> path

  request.to(url)
  |> result.map(fn(req) {
    req
    |> request.set_header("Accept", "application/json")
  })
}

pub fn is_service_running() {
  use req <- result.try(
    make_servive_req("") |> error.map_to_snag("Unable to make request"),
  )

  let res = httpc.send(req)

  case res {
    Error(_) -> Ok(False)
    Ok(v) -> Ok(v.status == 200)
  }
}

pub fn kill_service() {
  let browser_logger = logger.new("Browser")

  logger.info(browser_logger, "Killing browser service")

  use req <- result.try(
    make_servive_req("/api/close")
    |> error.map_to_snag("Unable to make request"),
  )

  use resp <- result.try(
    httpc.send(req) |> error.map_to_snag("unable to send request"),
  )

  case resp.status == 202 {
    True -> {
      logger.info(browser_logger, "Browser service killed")
      Ok(True)
    }
    _ -> Ok(False)
  }
}

fn start_service(browser_logger: logger.Logger) {
  case is_service_running() {
    Ok(False) -> {
      logger.info(browser_logger, "Starting browser service")

      let sub = process.new_subject()

      let sel =
        process.new_selector()
        |> process.select(sub)

      let _ =
        process.spawn_unlinked(fn() {
          let res = shellout.command("npm", ["run", "start:runner"], ".", [])
          process.send(sub, res)
        })

      let resp =
        sel
        |> process.selector_receive(4000)

      logger.info(
        browser_logger,
        "Browser service started" <> string.inspect(resp),
      )

      Nil
    }

    _ -> {
      logger.info(browser_logger, "Browser service already running")
      Nil
    }
  }
}
