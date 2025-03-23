import gleam/dict
import gleam/hackney
import gleam/http/request
import gleam/result
import services/dom

pub fn search(term: String) -> Result(List(dict.Dict(dom.Key, String)), Nil) {
  let assert Ok(req) = request.to("https://html.duckduckgo.com/html?q=" <> term)

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
    |> request.set_header("Connection", "keep-alive")
    |> request.set_header("Upgrade-Insecure-Requests", "1")
    |> request.set_header("Sec-Fetch-Dest", "document")
    |> request.set_header("Sec-Fetch-Mode", "navigate")
    |> request.set_header("Sec-Fetch-Site", "none")
    |> hackney.send
    |> result.replace_error(Nil),
  )

  case response.status {
    200 -> {
      Ok(dom.find_links(response.body))
    }
    _ -> {
      Error(Nil)
    }
  }
}
