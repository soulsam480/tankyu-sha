import content/source
import gleam/dynamic
import gleam/dynamic/decode
import gleam/json
import gleam/regexp
import gleam/result
import lib/error
import services/browser

/// we'll handle known feeds slight differently
/// end goal is we can handle all kinds of feeds
type KnownFeeds {
  LinkedIn
  Unknown
}

pub fn run(source: source.Source) {
  use kind <- result.try(feed_kind(source))

  case kind {
    LinkedIn -> {
      use response <- result.try(browser.load(source.url, ["LinkedIn"]) |> echo)

      use base_result <- result.try(
        decode_base_result(response)
        |> error.map_to_snag("Browser returned invalid response"),
      )

      case base_result {
        SuccessResponse(data) -> {
          use posts <- result.try(
            decode_post(data) |> error.map_to_snag("Unable to decode posts"),
          )

          Ok(posts)
        }
        ErrorResponse(_) -> {
          Ok([])
        }
      }
    }
    _ -> {
      Ok([])
    }
  }
}

pub fn main() {
  run(source.Source(
    source.Feed,
    "sime",
    "https://www.linkedin.com/in/susaatrevenuehero/",
  ))
  |> echo
}

fn feed_kind(source: source.Source) {
  use linkedin_regex <- result.try(
    regexp.from_string("linkedin.com")
    |> error.map_to_snag("Linkedin regex error"),
  )

  case regexp.check(linkedin_regex, source.url) {
    True -> Ok(LinkedIn)
    False -> Ok(Unknown)
  }
}

pub type BrowserResponse {
  SuccessResponse(data: dynamic.Dynamic)
  ErrorResponse(error: dynamic.Dynamic)
}

fn decode_base_result(json_str: String) {
  let success_decoder = {
    use data <- decode.field("data", decode.dynamic)
    decode.success(SuccessResponse(data:))
  }

  let error_decoder = {
    use data <- decode.field("error", decode.dynamic)

    decode.success(ErrorResponse(error: data))
  }

  json.parse(json_str, decode.one_of(success_decoder, [error_decoder]))
}

pub type Post {
  Post(id: Int, content: String)
}

fn decode_post(posts: dynamic.Dynamic) {
  let post_decoder = {
    use id <- decode.field("id", decode.int)
    use content <- decode.field("content", decode.string)

    decode.success(Post(id:, content:))
  }

  decode.run(posts, decode.list(post_decoder))
}
