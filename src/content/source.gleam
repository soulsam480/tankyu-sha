import gleam/dict
import gleam/option

pub type SourceProvider {
  Search
  Feed
  News
}

pub type Source {
  Source(provider: SourceProvider, url: String, meta: dict.Dict(String, String))
}

pub fn new(url: option.Option(String), kind: SourceProvider) {
  case url {
    option.Some(val) -> {
      Ok(Source(kind, val, dict.new()))
    }
    _ -> {
      Error(Nil)
    }
  }
}
