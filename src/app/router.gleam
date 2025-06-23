import app/controllers/task_runs
import app/router_context
import gleam/string_tree
import wisp

pub fn handle_request(context: router_context.RouterContext) -> wisp.Response {
  let req = context.req

  case wisp.path_segments(req) {
    [] -> home_page(req)

    ["task_runs", ..rest] -> {
      task_runs.route(router_context.RouterContext(..context, segments: rest))
    }

    _ -> wisp.not_found()
  }
}

fn home_page(_req: wisp.Request) -> wisp.Response {
  wisp.response(200)
  |> wisp.html_body(
    string_tree.new() |> string_tree.append("<p>Welcome to Tankyu-Sha</p>"),
  )
}
