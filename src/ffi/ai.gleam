import ffi/dom
import gleam/dict
import gleam/dynamic

// src/ffi/dom.ex
@external(erlang, "Elixir.Ai", "find_source_type")
pub fn find_source_type(dict: dict.Dict(dom.Key, String)) -> dynamic.Dynamic
