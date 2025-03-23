import gleam/dict

pub type Key {
  Link
  Title
}

// src/ffi/dom.ex
@external(erlang, "Elixir.Dom", "find_links")
pub fn find_links(document: String) -> List(dict.Dict(Key, String))
