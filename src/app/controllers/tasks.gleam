import app/router_context
import background_process/scheduler
import gleam/dynamic/decode
import gleam/http
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import lib/error
import models/task
import wisp

// JSON Payload & Decoder for Create/Update
// We'll use the same one for PUT (update) and POST (create)

pub type TaskPayload {
  TaskPayload(topic: String, schedule: String, delivery_route: String)
}

fn task_payload_decoder() {
  use topic <- decode.field("topic", decode.string)
  use schedule <- decode.field("schedule", decode.string)
  use delivery_route <- decode.field("delivery_route", decode.string)
  decode.success(TaskPayload(topic:, schedule:, delivery_route:))
}

// JSON Encoder

// Controller

pub fn route(ctx: router_context.RouterContext) -> wisp.Response {
  let router_context.RouterContext(req, segments, _, _) = ctx

  case req.method, segments {
    http.Get, [] -> index(ctx)
    http.Post, [] -> create(ctx)
    http.Get, [id_str] -> show(ctx, id_str)
    http.Put, [id_str] -> update(ctx, id_str)
    http.Delete, [id_str] -> delete(ctx, id_str)
    _, _ -> wisp.not_found()
  }
}

// GET /tasks
fn index(ctx: router_context.RouterContext) -> wisp.Response {
  case task.all(ctx.conn) {
    Ok(tasks) ->
      tasks
      |> list.map(task.to_json)
      |> json.array(fn(a) { a })
      |> json.to_string_tree
      |> wisp.json_response(200)
    Error(_) -> wisp.internal_server_error()
  }
}

// GET /tasks/:id
fn show(ctx: router_context.RouterContext, id_str: String) -> wisp.Response {
  let response = {
    use id <- result.try(int.parse(id_str) |> error.map_to_snag("Invalid id"))

    task.find(id, ctx.conn)
  }

  case response {
    Ok(task) ->
      wisp.json_response(task.to_json(task) |> json.to_string_tree, 200)
    Error(_) -> wisp.not_found()
  }
}

import gleam/uri
import models/source

// ... existing code ...

// POST /tasks
fn create(ctx: router_context.RouterContext) -> wisp.Response {
  use json_body <- wisp.require_json(ctx.req)

  let response = {
    use body <- result.try(
      decode.run(json_body, task_payload_decoder())
      |> error.map_to_snag("Invalid payload"),
    )

    use ts <- result.try(
      task.new()
      |> task.set_topic(body.topic)
      |> task.set_schedule(body.schedule)
      |> task.set_delivery_route(body.delivery_route)
      |> task.create(ctx.conn),
    )

    let _ = case uri.parse(body.topic) {
      Ok(_) -> {
        let assert Ok(_) =
          source.new()
          |> source.set_task_id(ts.id)
          |> source.set_kind(source.News)
          |> source.set_url(body.topic)
          |> source.create(ctx.conn)

        Ok(Nil)
      }
      Error(_) -> Ok(Nil)
    }

    let assert Ok(_) =
      scheduler.schedule_task(ts, ctx.conn, ctx.actor_registry.scheduler)

    Ok(ts)
  }

  case response {
    Ok(created_task) ->
      wisp.json_response(task.to_json(created_task) |> json.to_string_tree, 201)
    Error(_) -> wisp.bad_request()
  }
}

// PUT /tasks/:id
fn update(ctx: router_context.RouterContext, id_str: String) -> wisp.Response {
  use json_body <- wisp.require_json(ctx.req)

  let response = {
    use id <- result.try(int.parse(id_str) |> error.map_to_snag("Invalid id"))

    use payload <- result.try(
      decode.run(json_body, task_payload_decoder())
      |> error.map_to_snag("Invalid payload"),
    )

    use original_task <- result.try(task.find(id, ctx.conn))

    let task_to_update =
      task.Task(
        ..original_task,
        topic: payload.topic,
        schedule: payload.schedule,
        delivery_route: payload.delivery_route,
      )

    use _ <- result.try(task.update(task_to_update, ctx.conn))

    Ok(task_to_update)
  }

  case response {
    Ok(updated_task) ->
      wisp.json_response(task.to_json(updated_task) |> json.to_string_tree, 200)
    Error(_) -> wisp.bad_request()
  }
}

// DELETE /tasks/:id
fn delete(ctx: router_context.RouterContext, id_str: String) -> wisp.Response {
  let response = {
    use id <- result.try(int.parse(id_str) |> error.map_to_snag("Invalid id"))

    use task_to_delete <- result.try(task.find(id, ctx.conn))
    task.destroy(task_to_delete, ctx.conn)
  }

  case response {
    Ok(_) -> wisp.no_content()
    Error(_) -> wisp.not_found()
  }
}
