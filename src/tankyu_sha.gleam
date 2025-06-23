import app/router
import app/router_context
import background_process/supervisor
import envoy
import ffi/sqlite
import gleam/erlang/process
import gleam/int
import gleam/result
import lib/logger
import mist
import wisp
import wisp/wisp_mist

pub fn main() {
  use conn <- sqlite.with_connection(sqlite.db_path())

  // 1. start background processes
  process.spawn_unlinked(supervisor.start)

  wisp.configure_logger()

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

  let app_logger = logger.new("App")

  logger.info(app_logger, "running at http://localhost:" <> port)

  // 2. start web server
  process.sleep_forever()
}
