import content/source
import ffi/dom
import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/regexp
import gleam/result
import gleam/string
import gleam/string_tree
import lib/error
import services/internet_search
import snag
import survey

fn ask_string_qs(qs: survey.Survey) -> Result(String, snag.Snag) {
  let ans = survey.ask(qs, False)

  case ans {
    survey.StringAnswer(val) -> {
      Ok(val)
    }
    _ -> {
      snag.error("Invalid string answer")
    }
  }
}

pub fn run_app() {
  use val <- result.try(
    ask_string_qs(survey.new_question("Search term ? ", None, None, None, None))
    |> error.trap,
  )

  use scope <- result.try(
    ask_string_qs(survey.new_question(
      "Enter url to narrow search to a specific site ? or `Q` to skip: ",
      None,
      None,
      None,
      Some(fn(val) {
        case string.length(val) {
          0 -> val
          _ -> {
            case val {
              "Q" -> ""
              _ -> {
                let assert Ok(re) =
                  regexp.from_string(
                    "^[-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[a-zA-Z0-9()]{1,6}\\b(?:[-a-zA-Z0-9()@:%_\\+.~#?&//=]*)$",
                  )

                case regexp.check(re, val) {
                  True -> " site:" <> string.trim(val)
                  False -> ""
                }
              }
            }
          }
        }
      }),
    ))
    |> error.trap,
  )

  use search_results <- result.try(
    internet_search.search(val <> scope) |> error.trap,
  )

  let q =
    list.fold(search_results, string_tree.new(), fn(builder, it) {
      let assert Ok(title) = dict.get(it, dom.Title)
      let assert Ok(index) = dict.get(it, dom.Id)
      let assert Ok(link) = dict.get(it, dom.Link)

      builder
      |> string_tree.append(index)
      |> string_tree.append(": ")
      |> string_tree.append(title |> string.slice(0, 100) <> "..")
      |> string_tree.append("\n")
      |> string_tree.append("   link: ")
      |> string_tree.append(link)
      |> string_tree.append("\n")
    })
    |> string_tree.to_string()

  use opt <- result.try(
    ask_string_qs(survey.new_question(
      "Choose Source (enter index) \n" <> q,
      None,
      None,
      Some(fn(s) {
        let ind = int.parse(s)

        case ind {
          Ok(val) -> {
            val < list.length(search_results)
          }
          Error(_) -> False
        }
      }),
      None,
    ))
    |> error.trap,
  )

  use opt_val <- result.try(
    list.find(search_results, fn(it) {
      case dict.get(it, dom.Id) {
        Ok(val) -> val == opt
        _ -> False
      }
    })
    |> error.map_to_snag("Invalid option")
    |> error.trap,
  )

  use kind_index <- result.try(
    ask_string_qs(survey.new_question(
      "What kind of source this is ? (enter index)\n"
        <> "1. Feed\n"
        <> "2. News\n"
        <> "3. Blog\n",
      None,
      None,
      Some(fn(s) {
        let ind = int.parse(s)

        case ind {
          Ok(val) -> {
            val < 3
          }
          _ -> {
            False
          }
        }
      }),
      None,
    ))
    |> error.trap,
  )

  let source_type = {
    let assert Ok(ind) = int.parse(kind_index)

    case ind {
      1 -> source.Feed
      2 -> source.News
      3 -> source.Blog
      _ -> source.Blog
    }
  }

  let assert Ok(source) = source.new(opt_val, "linkedin", source_type)

  echo source

  Ok(source)
}
