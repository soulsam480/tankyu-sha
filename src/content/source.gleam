pub type SourceProvider {
  DuckDuckGo
  Feed
  News
  Blog
}

pub type Source {
  Source(provider: SourceProvider, name: String, url: String)
}
