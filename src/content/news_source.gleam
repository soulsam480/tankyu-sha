import content/source
import gleam/dynamic/decode
import gleam/option
import gleam/result
import gleam/string
import gleam/string_tree
import lib/error
import services/browser
import snag

pub fn run(source: source.Source) {
  use response <- result.try(browser.load(source.url, ["--kind=News"]))

  case response {
    browser.SuccessResponse(data) -> {
      use content <- result.try(
        decode.run(data, news_content_decoder())
        |> error.map_to_snag("Unable to decode news response"),
      )

      let res =
        string_tree.from_string(content.content)
        |> string_tree.append("\n")
        |> string_tree.append(
          "Posted by: "
          <> content.actor_name |> option.unwrap("Unknown")
          <> " on: "
          <> content.published_at |> option.unwrap("Unknown")
          <> " on the following site: "
          <> content.domain |> option.unwrap("Unknown"),
        )
        |> string_tree.to_string()

      Ok(res)
    }
    e -> {
      snag.error("Unable to load news: " <> string.inspect(e))
    }
  }
}

type NewsContent {
  NewsContent(
    content: String,
    title: option.Option(String),
    published_at: option.Option(String),
    domain: option.Option(String),
    actor_name: option.Option(String),
  )
}

fn news_content_decoder() -> decode.Decoder(NewsContent) {
  use content <- decode.field("content", decode.string)
  use title <- decode.field("title", decode.optional(decode.string))

  use published_at <- decode.field(
    "published_at",
    decode.optional(decode.string),
  )

  use domain <- decode.field("domain", decode.optional(decode.string))

  use actor_name <- decode.subfield(
    ["actor"],
    decode.optionally_at(["name"], option.None, decode.optional(decode.string)),
  )

  decode.success(NewsContent(
    content:,
    title:,
    published_at:,
    domain:,
    actor_name:,
  ))
}
