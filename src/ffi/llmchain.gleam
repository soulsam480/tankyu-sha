import gleam/option.{type Option}

@external(erlang, "Elixir.LLMChain", "split")
fn do_split_text(
  content: String,
  chunk_size: Int,
  chunk_overlap: Int,
) -> List(String)

pub fn split_text(
  content: String,
  chunk_size: Option(Int),
  chunk_overlap: Option(Int),
) -> List(String) {
  do_split_text(
    content,
    option.unwrap(chunk_size, 1000),
    option.unwrap(chunk_overlap, 200),
  )
}
