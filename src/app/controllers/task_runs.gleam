import app/router_context
import birl
import birl/duration
import gleam/http
import gleam/list
import gleam/result
import gleam/string
import gleam/string_tree
import models/source
import models/task
import models/task_run
import wisp

/// router for /task_runs
pub fn route(ctx: router_context.RouterContext) -> wisp.Response {
  let router_context.RouterContext(req, segments, _conn) = ctx

  case req.method, segments {
    http.Get, ["dash", ..] -> {
      dash(router_context.RouterContext(..ctx, segments: ["dash"]))
    }

    http.Post, ["dash", "queue", ..] -> {
      queue_new(
        router_context.RouterContext(..ctx, segments: ["dash", "queue"]),
      )
    }

    _, _ -> wisp.not_found()
  }
}

// POST /task_runs/dash/queue
fn queue_new(ctx: router_context.RouterContext) -> wisp.Response {
  let delivery_times = [
    birl.utc_now() |> birl.add(duration.hours(1)) |> birl.to_iso8601(),
    birl.utc_now() |> birl.add(duration.minutes(15)) |> birl.to_iso8601(),
    birl.utc_now() |> birl.add(duration.minutes(20)) |> birl.to_iso8601(),
  ]

  let articles = [
    "https://lite.cnn.com/2025/06/21/weather/heat-dome-climate",
    "https://lite.cnn.com/2025/06/21/politics/iran-b-2-bombers-trump",
    "https://lite.cnn.com/2025/06/20/us/mahmoud-khalil-ordered-released-by-judge",
    "https://lite.cnn.com/us/ice-immigration-officers-face-masks",
    "https://lite.cnn.com/2025/06/21/middleeast/americans-israel-desperate-get-out-intl-latam",
    "https://lite.cnn.com/2025/06/21/sport/jacob-misiorowski-125-year-old-record-spt",
  ]

  list.zip(list.shuffle(delivery_times), list.shuffle(articles))
  |> list.each(fn(it) {
    let #(delivery_time, article) = it

    let assert Ok(ts) =
      task.new()
      |> task.set_delivery_at(delivery_time)
      |> task.create(ctx.conn)

    source.new()
    |> source.set_task_id(ts.id)
    |> source.set_kind(source.News)
    |> source.set_url(article)
    |> source.create(ctx.conn)
  })

  wisp.accepted()
}

/// GET /task_runs/dash
fn dash(ctx: router_context.RouterContext) -> wisp.Response {
  let result = {
    use runs <- result.try(task_run.all(1, 100, ctx.conn))

    list.fold(
      runs,
      string_tree.new() |> string_tree.append("<body> <ol>"),
      fn(acc, curr) {
        acc
        |> string_tree.append(
          "<li> Run started at "
          <> curr.created_at
          <> "; last updated at "
          <> curr.updated_at
          <> ". Current status "
          <> string.inspect(curr.status)
          <> "with content <br/>"
          <> curr.content
          <> "</li>",
        )
      },
    )
    |> string_tree.append(
      "</ul>
<form id='queueForm'>
<button type='submit'> Queue</button>
</form>

    <script>
      document.getElementById('queueForm').addEventListener('submit', function(event) {
        event.preventDefault(); // Prevent default form submission

        fetch('/task_runs/dash/queue', {
          method: 'POST'
        })
        .then(response => {
          if (response.ok) {
            console.log('Successfully queued!');
          } else {
            console.error('Failed to queue:', response.statusText);
          }
        })
        .catch(error => {
          console.error('Error during fetch:', error);
        });
      });

    window.setTimeout(()=> window.location.reload(), 5000);
    </script>
    </body>",
    )
    |> Ok
  }

  case result {
    Ok(tree) -> wisp.response(200) |> wisp.html_body(tree)
    _ -> wisp.bad_request()
  }
}
