import ffi/sqlite
import wisp

pub type RouterContext {
  RouterContext(
    req: wisp.Request,
    segments: List(String),
    conn: sqlite.Connection,
  )
}
