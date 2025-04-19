import content/feed_source
import content/source
import envoy
import ffi/driver
import gleam/result

pub fn run(source: source.Source) {
  case source.provider {
    source.Feed -> feed_source.run(source)
    _ -> Ok(Nil)
  }
}

pub fn main() {
  use url <- result.try(envoy.get("URL"))

  // let _ = run(source.Source(source.Feed, "linkedin", url))

  echo driver.load(url)

  Ok(Nil)
}
