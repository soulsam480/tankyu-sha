import birl
import gleam/int
import gleam/result
import gleam/string
import gleam/string_tree
import models/source
import models/source_run

pub fn prepare_source_meta(
  tree: string_tree.StringTree,
  source_run: source_run.SourceRun,
  source: source.Source,
  index: Int,
) {
  string_tree.append(
    tree,
    int.to_string(index + 1)
      <> ". Extracted from "
      <> source.url
      <> ". "
      <> "The source is of type "
      <> string.inspect(source.kind)
      <> ". "
      <> "The data was collected at "
      <> {
      birl.parse(source_run.updated_at)
      |> result.unwrap(birl.now())
      |> birl.to_naive
    }
      <> "."
      <> "\n",
  )
}
