import content/source
import ffi/ai
import gleam/dynamic/decode
import gleam/result
import services/browser

pub fn run(source: source.Source) {
  todo
}

pub fn main() {
  let source =
    source.Source(
      source.News,
      "techcrunch",
      "https://www.ndtv.com/feature/experts-alarmed-after-some-chatgpt-users-experience-bizarre-delusions-feels-like-black-mirror-8397443",
    )

  use response <- result.try(browser.load(source.url, ["--kind=News"]))

  let _ = case response {
    browser.SuccessResponse(data) -> {
      use content <- result.try(decode.run(data, news_content_decoder()))

      let _ = ai.get_news_summary(content.content) |> echo

      Ok(Nil)
    }
    _ -> {
      Ok(Nil)
    }
  }

  Ok(Nil)
}

type NewsContent {
  NewsContent(content: String)
}

fn news_content_decoder() -> decode.Decoder(NewsContent) {
  use content <- decode.field("content", decode.string)
  decode.success(NewsContent(content:))
}
