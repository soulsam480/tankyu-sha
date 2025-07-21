import app/router_context
import ffi/ai
import gleam/dynamic/decode
import gleam/http
import gleam/list
import gleam/result
import gleam/string_tree
import lib/error
import services/config
import wisp

pub type Message {
  Message(role: String, content: String)
}

fn message_decoder() {
  use role <- decode.field("role", decode.string)
  use content <- decode.field("content", decode.string)
  decode.success(Message(role:, content:))
}

pub fn route(ctx: router_context.RouterContext) -> wisp.Response {
  let router_context.RouterContext(req, segments, _, _) = ctx

  case req.method, segments {
    http.Post, [] -> chat(ctx)
    _, _ -> wisp.not_found()
  }
}

fn chat(ctx: router_context.RouterContext) -> wisp.Response {
  use json_body <- wisp.require_json(ctx.req)

  let response = {
    use messages <- result.try(
      decode.run(json_body, decode.list(message_decoder()))
      |> error.map_to_snag("Invalid messages payload"),
    )

    use conf <- result.try(config.load())

    messages
    |> list.map(fn(msg) { msg.content })
    |> ai.chat(conf.summary_model_name, _, ai.empty_tools())
    |> error.map_to_snag("Failed to get chat response")
  }

  case response {
    Ok(_chat_response) -> wisp.json_response(string_tree.from_string("OK"), 200)
    Error(_) -> wisp.internal_server_error()
  }
}
