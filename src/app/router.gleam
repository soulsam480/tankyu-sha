import app/controllers/task_runs
import app/controllers/tasks
import app/router_context
import gleam/string_tree
import wisp

pub fn handle_request(context: router_context.RouterContext) -> wisp.Response {
  let req = context.req

  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  // Rewrite HEAD requests to GET requests and return an empty body.
  use req <- wisp.handle_head(req)

  case wisp.path_segments(req) {
    [] -> home_page(req)

    ["task_runs", ..rest] -> {
      task_runs.route(router_context.RouterContext(..context, segments: rest))
    }

    ["tasks", ..rest] -> {
      tasks.route(router_context.RouterContext(..context, segments: rest))
    }

    _ -> wisp.not_found()
  }
}

fn home_page(_req: wisp.Request) -> wisp.Response {
  wisp.response(200)
  |> wisp.html_body(string_tree.from_string("<p>Welcome to Tankyu-Sha</p>"))
}
