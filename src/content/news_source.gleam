import ffi/sqlite
import gleam/dynamic/decode
import gleam/option
import gleam/result
import gleam/string
import gleam/string_tree
import lib/error
import models/source
import services/browser
import snag

// type Document {
//   Document(index: Int, doc: String)
// }

pub fn run(source: source.Source) {
  use _conn <- sqlite.with_connection(sqlite.db_path())
  use _content <- result.try(load_content(source))

  Ok("")
}

// pub fn main() {
//   use conn <- sqlite.with_connection(sqlite.db_path())
//
//   use _ <- result.try(
//     sqlite.exec(conn, "select * from digests;", [])
//     |> echo
//     |> error.map_to_snag("unable to read")
//     |> error.trap,
//   )
//
//   use _ <- result.try(
//     sqlite.exec(conn, "delete from digests", [])
//     |> error.map_to_snag("invalid delete")
//     |> error.trap,
//   )
//
//   let chunks =
//     llmchain.split_text(
//       "One Piece (stylized in all caps) is a Japanese manga series written and illustrated by Eiichiro Oda. It follows the adventures of Monkey D. Luffy and his crew, the Straw Hat Pirates, as he explores the Grand Line in search of the mythical treasure known as the 'One Piece' to become the next King of the Pirates.
//
// It has been serialized in Shueisha's shōnen manga magazine Weekly Shōnen Jump since July 1997, with its chapters compiled in 111 tankōbon volumes as of March 2025. The manga series was licensed for an English language release in North America and the United Kingdom by Viz Media and in Australia by Madman Entertainment. Becoming a media franchise, it has been adapted into a festival film by Production I.G, and an anime series by Toei Animation, which began broadcasting in 1999. Additionally, Toei has developed 14 animated feature films and one original video animation. Several companies have developed various types of merchandising and media, such as a trading card game and video games. Netflix released a live action TV series adaptation in 2023.
//
// It has received praise for the storytelling, world-building, art, characterization, and humour. It has received many awards and is ranked by critics, reviewers, and readers as one of the best manga of all time. By August 2022, it had over 516.6 million copies in circulation in 61 countries and regions worldwide, making it the best-selling manga series in history, and the best-selling comic series printed in a book volume. Several volumes of the manga have broken publishing records, including the highest initial print run of any book in Japan. In 2015 and 2022, One Piece set the Guinness World Record for 'the most copies published for the same comic book series by a single author'. It was the best-selling manga for 11 consecutive years from 2008 to 2018 and is the only manga that had an initial print of volumes of above 3 million continuously for more than 10 years, as well as the only one that had achieved more than 1 million copies sold in all of its over 100 published tankōbon volumes. One Piece is the only manga whose volumes have ranked first every year in Oricon's weekly comic chart existence since 2008.",
//       option.None,
//       option.None,
//     )
//     |> list.index_map(fn(it, index) { Document(index, it) })
//
//   use res <- result.try(
//     ai.embed(chunks |> list.map(fn(it) { it.doc }), option.None)
//     |> echo
//     |> error.map_to_snag("invalid embed")
//     |> error.trap,
//   )
//
//   use embeds <- result.try(
//     ai.pluck_embedding(res)
//     |> error.trap,
//   )
//
//   list.index_map(embeds, fn(it, index) {
//     let assert Ok(doc) = list.find(chunks, fn(it) { it.index == index })
//
//     echo digest.new()
//       |> digest.set_content(doc.doc)
//       |> digest.set_content_embedding(it)
//       |> digest.create(conn)
//   })
//
//   use query <- result.try(
//     ai.embed(["what is one piece ?"], option.None)
//     |> error.map_to_snag("invalid embed")
//     |> error.trap,
//   )
//
//   use q_embed <- result.try(
//     ai.pluck_embedding(query)
//     |> error.trap,
//   )
//
//   echo sqlite.exec(
//     conn,
//     "select
//   id,
//   distance,
//   content
// from digests
// where content_embedding match vec_f32(?)
// and k = 10
// order by distance asc;",
//     [sqlite.vec(list.first(q_embed) |> result.unwrap([]))],
//   )
//
//   Ok(Nil)
// }

fn load_content(source: source.Source) {
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
