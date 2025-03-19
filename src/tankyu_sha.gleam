import gleam/result
import shellout

pub fn main() {
  shellout.command(
    run: "pwd",
    // with: ["fetch", "--dump", "https://sambitsahoo.com/blog/hello-world.html"],
    with: [],
    in: "src",
    opt: [shellout.LetBeStdout],
  )
  |> result.map(fn(res) { echo res })
  |> result.map_error(fn(res) { echo res })
}
