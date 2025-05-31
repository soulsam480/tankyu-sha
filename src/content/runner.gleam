import content/feed_source
import content/news_source
import content/source

// NOTE: we need to put the entire workflow here
pub fn run(source: source.Source) {
  case source.provider {
    source.Feed -> feed_source.run(source)
    source.News -> news_source.run(source)
    _ -> Ok("")
  }
}
