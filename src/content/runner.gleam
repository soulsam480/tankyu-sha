import content/feed_source
import content/news_source
import models/source

// NOTE: we need to put the entire workflow here
pub fn run(soc: source.Source) {
  case soc.kind {
    source.Feed -> feed_source.run(soc)
    source.News -> news_source.run(soc)
    _ -> Ok("")
  }
}
