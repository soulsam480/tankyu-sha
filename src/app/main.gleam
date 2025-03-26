import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleam/string_tree
import services/dom
import services/google
import survey

fn ask_string_qs(qs: survey.Survey) -> Result(String, Nil) {
  let ans = survey.ask(qs, False)

  case ans {
    survey.StringAnswer(val) -> {
      Ok(val)
    }
    _ -> {
      Error(Nil)
    }
  }
}

pub fn run_app() {
  use val <- result.try(
    ask_string_qs(survey.new_question("Search term ?", None, None, None, None)),
  )

  use search_results <- result.try(google.search(val))

  let q =
    list.index_fold(search_results, string_tree.new(), fn(builder, it, index) {
      let assert Ok(title) = dict.get(it, dom.Title)

      builder
      |> string_tree.append(int.to_string(index))
      |> string_tree.append(": ")
      |> string_tree.append(title |> string.slice(0, 20))
      |> string_tree.append("\n")
    })
    |> string_tree.to_string()

  use opt <- result.try(
    ask_string_qs(survey.new_question(
      "Choose Source \n" <> q,
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
    )),
  )

  echo opt

  Ok(Nil)
}
