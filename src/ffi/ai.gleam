import ffi/dom
import gleam/dict
import gleam/dynamic

// src/ffi/dom.ex
@external(erlang, "Elixir.Ai", "find_source_type")
pub fn find_source_type(dict: dict.Dict(dom.Key, String)) -> dynamic.Dynamic

@external(erlang, "Elixir.Ai", "get_feed_analysis")
pub fn get_feed_analysis(posts: String) -> dynamic.Dynamic

@external(erlang, "Elixir.Ai", "get_news_summary")
pub fn get_news_summary(post: String) -> dynamic.Dynamic
