import gleam/dict
import gleam/dynamic
import gleam/option.{type Option}
import gleam/result
import lib/error

// src/ffi/dom.ex
// @external(erlang, "Elixir.Ai", "find_source_type")
// fn find_source_type(dict: dict.Dict(dom.Key, String)) -> dynamic.Dynamic

@external(erlang, "Elixir.Ai", "get_feed_analysis")
fn get_feed_analysis(posts: String) -> dict.Dict(String, String)

@external(erlang, "Elixir.Ai", "get_news_summary")
fn get_news_summary(post: String) -> dict.Dict(String, String)

pub type Operation {
  SourceType
  FeedAnalysis
  ContentAnalysis
}

pub fn analyse(op: Operation, payload: String) {
  case op {
    SourceType -> {
      // TODO: need to clean this
      Ok("Not implemented")
    }
    FeedAnalysis -> {
      get_feed_analysis(payload) |> dict.get("response")
    }
    ContentAnalysis -> {
      get_news_summary(payload) |> dict.get("response")
    }
  }
  |> error.map_to_snag("Unable to run analysis")
}

@external(erlang, "Elixir.Ai", "embed")
fn do_embed(
  input: List(String),
  model: String,
) -> Result(dict.Dict(String, List(List(Float))), dynamic.Dynamic)

pub fn embed(input: List(String), model: Option(String)) {
  do_embed(input, option.unwrap(model, "nomic-embed-text:latest"))
}

pub fn pluck_embedding(res: dict.Dict(String, List(List(Float)))) {
  dict.get(res, "embeddings")
  |> error.map_to_snag("invalid dict")
}
