import background_process/registry
import ffi/sqlite
import wisp

pub type RouterContext {
  RouterContext(
    req: wisp.Request,
    segments: List(String),
    conn: sqlite.Connection,
    actor_registry: registry.Registry,
  )
}
