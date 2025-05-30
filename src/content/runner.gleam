import content/feed_source
import content/news_source
import content/source

pub fn run(source: source.Source) {
  case source.provider {
    source.Feed -> feed_source.run(source)
    source.News -> news_source.run(source)
    _ -> Ok("")
  }
}
