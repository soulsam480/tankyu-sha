import ffi/dom
import gleam/dict

pub type SourceProvider {
  Search
  Feed
  News
}

pub type Source {
  Source(provider: SourceProvider, name: String, url: String)
}

pub fn new(res: dict.Dict(dom.Key, String), name: String, kind: SourceProvider) {
  case dict.get(res, dom.Link) {
    Ok(val) -> {
      Ok(Source(kind, name, val))
    }
    _ -> {
      Error(Nil)
    }
  }
}
