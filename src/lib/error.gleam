import gleam/result
import gleam/string
import snag

pub fn trap(from: Result(a, b)) -> Result(a, b) {
  case result.is_error(from) {
    True -> echo from
    _ -> from
  }
}

pub fn map_to_snag(from: Result(a, b), error: String) -> Result(a, snag.Snag) {
  result.map_error(from, fn(e) { snag.new(error <> "::" <> string.inspect(e)) })
}
