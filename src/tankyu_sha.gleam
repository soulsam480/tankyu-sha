import app/router
import app/router_context
import background_process/supervisor
import envoy
import ffi/sqlite
import gleam/erlang/process
import gleam/int
import gleam/result
import mist
import services/config
import wisp
import wisp/wisp_mist

pub fn main() {
  use conn <- sqlite.with_connection(sqlite.db_path())

  // initialize config if not present
  let assert Ok(_) = config.init()

  let sub = process.new_subject()

  // 1. start background processes
  process.spawn_unlinked(fn() { supervisor.start(sub) })

  let actor_registry = process.receive_forever(sub)

  wisp.configure_logger()
  wisp.set_logger_level(wisp.InfoLevel)

  let secret_key_base = wisp.random_string(64)

  let port =
    envoy.get("PORT")
    |> result.unwrap("8080")

  let assert Ok(_) =
    wisp_mist.handler(
      fn(req) {
        router.handle_request(router_context.RouterContext(
          req:,
          conn:,
          segments: wisp.path_segments(req),
          actor_registry:,
        ))
      },
      secret_key_base,
    )
    |> mist.new
    |> mist.port(
      port
      |> int.parse()
      |> result.unwrap(8080),
    )
    |> mist.start

  // 2. start web server
  process.sleep_forever()
}
