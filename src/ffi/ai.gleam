import gleam/dict
import gleam/dynamic
import gleam/regexp
import gleam/result
import lib/error
import services/config

// src/ffi/dom.ex
// @external(erlang, "Elixir.Ai", "find_source_type")
// fn find_source_type(dict: dict.Dict(dom.Key, String)) -> dynamic.Dynamic

@external(erlang, "Elixir.Ai", "get_feed_analysis")
fn get_feed_analysis(
  posts: String,
  model: String,
) -> Result(dict.Dict(String, String), Nil)

@external(erlang, "Elixir.Ai", "get_news_summary")
fn get_news_summary(
  post: String,
  model: String,
) -> Result(dict.Dict(String, String), Nil)

pub type Operation {
  SourceType
  FeedAnalysis
  ContentAnalysis
}

pub fn analyse(op: Operation, payload: String) {
  use conf <- result.try(config.load())

  case op {
    SourceType -> {
      // TODO: need to clean this
      Ok("Not implemented")
    }
    FeedAnalysis -> {
      get_feed_analysis(payload, conf.summary_model_name)
      |> result.map(dict.get(_, "response"))
      |> result.flatten
      |> result.map(strip_thinking)
      |> result.flatten
    }
    ContentAnalysis -> {
      get_news_summary(payload, conf.summary_model_name)
      |> result.map(dict.get(_, "response"))
      |> result.flatten
      |> result.map(strip_thinking)
      |> result.flatten
    }
  }
  |> error.map_to_snag("Unable to run analysis")
}

@external(erlang, "Elixir.Ai", "embed")
fn do_embed(
  input: List(String),
  model: String,
) -> Result(dict.Dict(String, List(List(Float))), dynamic.Dynamic)

pub fn embed(input: List(String)) {
  use conf <- result.try(config.load())

  do_embed(input, conf.embedding_model_name)
  |> error.map_to_snag("Unable to embed")
}

pub fn pluck_embedding(res: dict.Dict(String, List(List(Float)))) {
  dict.get(res, "embeddings")
  |> error.map_to_snag("Invalid embedding response")
}

fn strip_thinking(from: String) {
  use think_re <- result.try(
    regexp.compile("<think>[\\s\\S]*?<\\/think>", regexp.Options(True, True))
    |> result.replace_error(Nil),
  )

  Ok(regexp.replace(think_re, from, ""))
}
