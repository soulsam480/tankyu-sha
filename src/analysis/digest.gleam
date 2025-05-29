import ffi/ai

pub fn from_payload(payload: String) {
  echo "Showing analysis"

  let _ = ai.get_feed_analysis(payload) |> echo

  Ok([])
}
