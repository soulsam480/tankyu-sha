import ffi/dom
import gleam/dict
import gleam/dynamic/decode
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/string_tree
import gleam/uri
import lib/error
import services/browser
import snag

/// Duck Duck go simple search
/// can get rate limited or IP banned
pub fn ddg_simple(
  term: String,
) -> Result(List(dict.Dict(dom.Key, String)), snag.Snag) {
  use req <- result.try(
    request.to(
      "https://html.duckduckgo.com/html?q=" <> uri.percent_encode(term),
    )
    |> error.map_to_snag("Unable to create request")
    |> error.trap,
  )

  use response <- result.try(
    req
    |> request.set_header(
      "User-Agent",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36",
    )
    |> request.set_header(
      "Accept",
      "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
    )
    |> request.set_header("Accept-Language", "en-US,en;q=0.5")
    |> request.set_header("DNT", "1")
    // |> request.set_header("Connection", "keep-alive")
    |> request.set_header("Upgrade-Insecure-Requests", "1")
    |> request.set_header("Sec-Fetch-Dest", "document")
    |> request.set_header("Sec-Fetch-Mode", "navigate")
    |> request.set_header("Sec-Fetch-Site", "none")
    |> httpc.send
    |> error.map_to_snag("Unable to send request with error: ")
    |> error.trap,
  )

  case response.status {
    200 -> {
      dom.find_links(response.body)
      |> list.map(fn(it) {
        let res = {
          use link <- result.try(dict.get(it, dom.Link))
          use parsed <- result.try(uri.parse(link))

          case parsed.query {
            option.Some(str) -> {
              use parsed_query <- result.try(uri.parse_query(str))

              use internal_link <- result.try(
                parsed_query
                |> list.key_find("uddg"),
              )

              Ok(dict.merge(
                it,
                dict.new() |> dict.insert(dom.Link, internal_link),
              ))
            }
            _ -> Ok(it)
          }
        }

        result.unwrap(res, it)
      })
      |> Ok
    }
    _ -> {
      snag.error(
        "Search request failed with " <> int.to_string(response.status),
      )
    }
  }
}

/// Duck Duck go internet search
/// Range -> d,m,h,y
/// Pages -> any integer, larger the count slower the results fetching
/// Section -> news, web
///
pub type DdgParam {
  Pages(count: String)
  Range(from: String)
  Section(in: String)
}

fn ddg_query_params(params: List(DdgParam)) -> String {
  list.fold(params, string_tree.new(), fn(builder, param) {
    case param {
      Range(from) -> {
        builder
        |> string_tree.append("&df=" <> from)
        |> string_tree.append("&ndf=" <> from)
      }

      Section(in) -> {
        builder
        |> string_tree.append("&ia=" <> in)
        |> string_tree.append("&iar=" <> in)
      }

      _ -> builder
    }
  })
  |> string_tree.to_string()
}

fn ddg_pages(pages: List(DdgParam)) -> String {
  list.find_map(pages, fn(it) {
    case it {
      Pages(count) -> Ok("pages=" <> count)
      _ -> Ok("pages=1")
    }
  })
  |> result.unwrap("pages=1")
}

pub type SearchResult {
  SearchResult(
    id: String,
    title: String,
    description: String,
    link: option.Option(String),
    published_at: option.Option(String),
    publisher: option.Option(String),
  )
}

fn search_result_decoder() -> decode.Decoder(SearchResult) {
  use id <- decode.field("id", decode.string)
  use title <- decode.field("title", decode.string)
  use description <- decode.field("description", decode.string)

  use link <- decode.optional_field(
    "link",
    option.None,
    decode.optional(decode.string),
  )

  use published_at <- decode.optional_field(
    "published_at",
    option.None,
    decode.optional(decode.string),
  )

  use publisher <- decode.optional_field(
    "publisher",
    option.None,
    decode.optional(decode.string),
  )

  decode.success(SearchResult(
    id:,
    title:,
    description:,
    link:,
    published_at:,
    publisher:,
  ))
}

/// available values for range -> h,d,m,y
pub fn ddg(
  term: String,
  params: List(DdgParam),
) -> Result(List(SearchResult), snag.Snag) {
  use response <- result.try(
    browser.load(
      {
        "https://duckduckgo.com?q="
        <> uri.percent_encode(term)
        <> ddg_query_params(params)
      },
      ["kind=Search", ddg_pages(params)],
    ),
  )

  case response {
    browser.SuccessResponse(data) -> {
      use results <- result.try(
        decode.run(data, decode.list(search_result_decoder()))
        |> error.map_to_snag("Unable to decode search results"),
      )

      Ok(results)
    }
    _ -> {
      Ok([])
    }
  }
}
