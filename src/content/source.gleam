import ffi/dom
import gleam/dict

pub type SourceProvider {
  Search
  Feed
  News
}

pub type Source {
  Source(provider: SourceProvider, url: String, meta: dict.Dict(String, String))
}

pub fn new(res: dict.Dict(dom.Key, String), kind: SourceProvider) {
  case dict.get(res, dom.Link) {
    Ok(val) -> {
      Ok(Source(kind, val, dict.new()))
    }
    _ -> {
      Error(Nil)
    }
  }
}
