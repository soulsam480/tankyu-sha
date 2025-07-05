import app/router_context
import gleam/http
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import lib/error
import models/task_run
import wisp

// Controller

pub fn route(ctx: router_context.RouterContext) -> wisp.Response {
  let router_context.RouterContext(req, segments, _, _) = ctx

  case req.method, segments {
    http.Get, [] -> index(ctx)
    http.Get, [id_str] -> show(ctx, id_str)
    _, _ -> wisp.not_found()
  }
}

// GET /task_runs
fn index(ctx: router_context.RouterContext) -> wisp.Response {
  case task_run.all(1, 100, ctx.conn) {
    Ok(task_runs) ->
      task_runs
      |> list.map(task_run.to_json)
      |> json.array(fn(a) { a })
      |> json.to_string_tree
      |> wisp.json_response(200)
    Error(_) -> wisp.internal_server_error()
  }
}

// GET /task_runs/:task_id
fn show(ctx: router_context.RouterContext, id_str: String) -> wisp.Response {
  let response = {
    use id <- result.try(int.parse(id_str) |> error.map_to_snag("Invalid id"))

    task_run.of_task(id, ctx.conn)
  }

  case response {
    Ok(task_runs) ->
      task_runs
      |> list.map(task_run.to_json)
      |> json.array(fn(a) { a })
      |> json.to_string_tree
      |> wisp.json_response(200)
    Error(_) -> wisp.not_found()
  }
}
