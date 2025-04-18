import ffi/dom
import gleam/dict
import gleam/hackney
import gleam/http/request
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/uri
import lib/error
import snag

pub fn search(
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
    |> hackney.send
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
