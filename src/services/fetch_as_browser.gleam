import gleam/hackney
import gleam/http/request
import gleam/result
import lib/error

pub fn get(url: String) {
  use req <- result.try(
    request.to(url)
    |> error.map_to_snag("Unable to create request")
    |> error.trap,
  )

  use response <- result.try(
    req
    |> request.set_header(
      "User-Agent",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36",
    )
    |> request.set_header("Accept", "*/*")
    |> request.set_header(
      "Cookie",
      "JSESSIONID=ajax:5431906276052633020; lang=v=2&lang=en-us; bcookie=\"v=2&fd1ad00c-c742-4a0d-81bb-e4aac72a9e41\"; bscookie=\"v=1&20250406063946d3d2c4af-6a15-4f42-8a82-11aeca80c36bAQGmBg2MZXxmEc-Ye2dGDqNnT-f0fNeF\"; lidc=\"b=OGST07:s=O:r=O:a=O:p=O:g=3158:u=1:x=1:i=1743921586:t=1744007986:v=2:sig=AQFdH083gptSZYFaT4FsCd4vz2MTUXQD\"",
    )
    |> request.set_header("Referer", url)
    |> request.set_header("Accept-Language", "en-US,en;q=0.5")
    |> request.set_header("DNT", "1")
    |> request.set_header(
      "Sec-Ch-Ua",
      "\"Chromium\";v=\"135\", \"Not-A.Brand\";v=\"8\"",
    )
    |> request.set_header("Sec-Ch-Ua-Mobile", "?0")
    |> request.set_header("Sec-Ch-Ua-Platform", "\"macOS\"")
    |> request.set_header("Cache-Control", "no-cache")
    |> request.set_header("Connection", "keep-alive")
    |> request.set_header("Upgrade-Insecure-Requests", "1")
    |> request.set_header("Sec-Fetch-Dest", "document")
    |> request.set_header("Sec-Fetch-Mode", "navigate")
    |> request.set_header("Sec-Fetch-Site", "same-origin")
    |> hackney.send
    |> error.map_to_snag("Unable to send request with error: ")
    |> error.trap,
  )

  echo response.body

  Ok(Nil)
}
