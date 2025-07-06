import gleam/dynamic/decode
import gleam/erlang/application
import gleam/json
import gleam/result
import lib/error
import simplifile
import snag

pub type Config {
  Config(
    // path to the chrome binary, passed as is to playwright
    chrome_path: String,
    // model to use for source run and parent task run summaries
    // NOTE: bigger the model <> larger the memory consumption <> slower the summaries
    summary_model_name: String,
    // model to use for embedding the source run and parent task run content
    // NOTE: rn the original text content is summarized, and source material is deleted
    // this is to use less storage and memory
    embedding_model_name: String,
    // show ddg results with this range d,w,m,y
    ddg_result_range: String,
    // when consuming search results, take the below count from first page
    // default 5, set to -1 to take all
    max_search_source_results: Int,
    /// bigger count increases memory usage
    ingestor_actor_pool_count: Int,
    // default 2, deleted after 2 days
    // delete embeddings after n days from run
    document_expiry_after_days: Int,
  )
}

fn get_path() {
  use priv_dir <- result.try(
    application.priv_directory("tankyu_sha")
    |> error.map_to_snag("Unable to get priv dir"),
  )

  Ok(priv_dir <> "/app_config.json")
}

pub fn load() {
  use file_path <- result.try(get_path())

  use content <- result.try(
    simplifile.read(file_path) |> error.map_to_snag("Unable to read file"),
  )

  use conf <- result.try(
    json.parse(content, config_decoder()) |> error.map_to_snag("Invalid config"),
  )

  Ok(conf)
}

pub fn save(conf: Config) {
  use file_path <- result.try(get_path())

  let assert Ok(_) =
    simplifile.write(file_path, conf |> to_json |> json.to_string)

  Ok(Nil)
}

pub fn init() {
  use file_path <- result.try(get_path())

  case simplifile.is_file(file_path) {
    Ok(True) -> {
      Ok(Nil)
    }

    Ok(False) -> {
      let _ =
        Config(
          chrome_path: "/Applications/Chromium.app/Contents/MacOS/Chromium",
          ddg_result_range: "d",
          embedding_model_name: "nomic-embed-text:latest",
          ingestor_actor_pool_count: 2,
          max_search_source_results: 5,
          summary_model_name: "llama3.2:3b",
          document_expiry_after_days: 2,
        )
        |> save()

      Ok(Nil)
    }

    _ -> {
      snag.error("Unable to read config file")
    }
  }
}

fn config_decoder() -> decode.Decoder(Config) {
  use chrome_path <- decode.field("chrome_path", decode.string)
  use summary_model_name <- decode.field("summary_model_name", decode.string)
  use embedding_model_name <- decode.field(
    "embedding_model_name",
    decode.string,
  )
  use ddg_result_range <- decode.field("ddg_result_range", decode.string)

  use max_search_source_results <- decode.field(
    "max_search_source_results",
    decode.int,
  )

  use ingestor_actor_pool_count <- decode.field(
    "ingestor_actor_pool_count",
    decode.int,
  )

  use document_expiry_after_days <- decode.optional_field(
    "document_expiry_after_days",
    -1,
    decode.int,
  )

  decode.success(Config(
    chrome_path:,
    summary_model_name:,
    embedding_model_name:,
    ddg_result_range:,
    max_search_source_results:,
    ingestor_actor_pool_count:,
    document_expiry_after_days:,
  ))
}

fn to_json(config: Config) -> json.Json {
  let Config(
    chrome_path:,
    summary_model_name:,
    embedding_model_name:,
    ddg_result_range:,
    max_search_source_results:,
    ingestor_actor_pool_count:,
    document_expiry_after_days:,
  ) = config

  json.object([
    #("chrome_path", json.string(chrome_path)),
    #("summary_model_name", json.string(summary_model_name)),
    #("embedding_model_name", json.string(embedding_model_name)),
    #("ddg_result_range", json.string(ddg_result_range)),
    #("max_search_source_results", json.int(max_search_source_results)),
    #("ingestor_actor_pool_count", json.int(ingestor_actor_pool_count)),
    #("document_expiry_after_days", json.int(document_expiry_after_days)),
  ])
}

pub fn main() {
  init()
}
