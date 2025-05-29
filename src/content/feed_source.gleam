import content/source
import gleam/dynamic
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option
import gleam/regexp
import gleam/result
import gleam/string
import gleam/string_tree
import lib/error
import services/browser
import snag

/// we'll handle known feeds slight differently
/// end goal is we can handle all kinds of feeds
type KnownFeeds {
  LinkedIn
  Unknown
}

pub fn run(source: source.Source) {
  get_feed_posts(source)
}

fn get_feed_posts(source: source.Source) {
  use kind <- result.try(feed_kind(source))

  case kind {
    LinkedIn -> {
      use base_result <- result.try(
        browser.load(source.url, ["--kind=LinkedIn"]),
      )

      case base_result {
        browser.SuccessResponse(data) -> {
          use posts <- result.try(
            linked_in_response_decoder(data)
            |> error.map_to_snag("Unable to decode posts"),
          )

          Ok(posts |> linked_in_to_md())
        }

        browser.ErrorResponse(_) -> {
          snag.error("Browser returned invalid response")
        }
      }
    }
    un -> {
      snag.error("Unknown feed type" <> string.inspect(un))
    }
  }
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

pub type Post {
  Post(
    id: Int,
    content: String,
    actor_name: option.Option(String),
    actor_description: option.Option(String),
    time_ago: option.Option(String),
  )
}

fn post_decoder() -> decode.Decoder(Post) {
  use id <- decode.field("id", decode.int)
  use content <- decode.field("content", decode.string)

  use actor_name <- decode.subfield(
    ["actor"],
    decode.optionally_at(
      ["actor_name"],
      option.None,
      decode.optional(decode.string),
    ),
  )

  use actor_description <- decode.subfield(
    ["actor"],
    decode.optionally_at(
      ["description"],
      option.None,
      decode.optional(decode.string),
    ),
  )

  use time_ago <- decode.field("time_ago", decode.optional(decode.string))

  decode.success(Post(id:, content:, actor_name:, actor_description:, time_ago:))
}

pub type CompanyInfo {
  CompanyInfo(
    company_name: String,
    company_size: String,
    founded: String,
    headquarters: String,
    industry: String,
    overview: String,
    specialties: String,
    website_url: option.Option(String),
  )
}

fn company_info_decoder() -> decode.Decoder(CompanyInfo) {
  use company_name <- decode.field("company_name", decode.string)
  use company_size <- decode.field("company_size", decode.string)
  use founded <- decode.field("founded", decode.string)
  use headquarters <- decode.field("headquarters", decode.string)
  use industry <- decode.field("industry", decode.string)
  use overview <- decode.field("overview", decode.string)
  use specialties <- decode.field("specialties", decode.string)
  use website_url <- decode.field("website_url", decode.optional(decode.string))

  decode.success(CompanyInfo(
    company_name:,
    company_size:,
    founded:,
    headquarters:,
    industry:,
    overview:,
    specialties:,
    website_url:,
  ))
}

pub type LinkedInResponse {
  LinkedInResponse(posts: List(Post), company_info: option.Option(CompanyInfo))
}

fn linked_in_response_decoder(data: dynamic.Dynamic) {
  let resp_decoder = {
    use posts <- decode.field("posts", decode.list(post_decoder()))
    use company_info <- decode.field(
      "company_info",
      decode.optional(company_info_decoder()),
    )

    decode.success(LinkedInResponse(posts:, company_info:))
  }

  decode.run(data, resp_decoder)
}

pub fn linked_in_to_md(resp: LinkedInResponse) {
  let response = string_tree.new()

  case resp.company_info {
    option.Some(company_info) -> {
      response
      |> string_tree.append("## Company Info \n")
      |> string_tree.append("- name: " <> company_info.overview <> "\n")
      |> string_tree.append("- description: " <> company_info.overview <> "\n")
      |> string_tree.append(
        "- profile url: "
        <> company_info.website_url |> option.unwrap("Unknown")
        <> "\n",
      )

      Nil
    }
    option.None -> {
      Nil
    }
  }

  resp.posts
  |> list.fold(response, fn(builder, post) {
    string_tree.append(builder, "\n")
    |> string_tree.append("## Post " <> post.id |> int.to_string <> "\n")
    |> string_tree.append("### From actor\n")
    |> string_tree.append(
      "- name: " <> post.actor_name |> option.unwrap("Unknown") <> "\n",
    )
    |> string_tree.append(
      "- description: "
      <> post.actor_description |> option.unwrap("Unknown")
      <> "\n",
    )
    |> string_tree.append("### Content\n")
    |> string_tree.append(post.content <> "\n")
    |> string_tree.append(
      "was posted" <> post.time_ago |> option.unwrap("Unknown"),
    )
  })
  |> string_tree.to_string()
}
