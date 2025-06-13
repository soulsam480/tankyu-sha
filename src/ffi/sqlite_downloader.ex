@moduledoc """
taken from https://github.com/joelpaulkoch/sqlite_vec/blob/main/lib/sqlite_vec/downloader.ex
"""
defmodule SqliteDownloader do
  use OctoFetch,
    latest_version: "0.1.6",
    github_repo: "asg017/sqlite-vec",
    download_versions: %{
      "0.1.6" => [
        {:darwin, :amd64, "35d014e5f7bcac52645a97f1f1ca34fdb51dcd61d81ac6e6ba1c712393fbf8fd"},
        {:darwin, :arm64, "142e195b654092632fecfadbad2825f3140026257a70842778637597f6b8c827"},
        {:linux, :amd64, "438e0df29f3f8db3525b3aa0dcc0a199869c0bcec9d7abc5b51850469caf867f"},
        {:linux, :arm64, "d6e4ba12c5c0186eaab42fb4449b311008d86ffd943e6377d7d88018cffab3aa"},
        {:windows, :amd64, "f1c615577ad2e692d1e2fe046fe65994dafd8a8cae43e9e864f5f682dc295964"}
      ]
    }

  @impl true
  def download_name(version, :darwin, arch), do: download_name(version, :macos, arch)
  def download_name(version, os, :amd64), do: download_name(version, os, :x86_64)
  def download_name(version, os, :arm64), do: download_name(version, os, :aarch64)

  def download_name(version, os, arch), do: "sqlite-vec-#{version}-loadable-#{os}-#{arch}.tar.gz"

  def pre_download_hook(_file, output_dir) do
    if library_exists?(output_dir) do
      :skip
    else
      :cont
    end
  end

  defp library_exists?(output_dir) do
    matches =
      output_dir
      |> Path.join("vec0.*")
      |> Path.wildcard()

    matches != []
  end

  def post_write_hook(file) do
    _output_dir = file |> Path.dirname() |> Path.join("..") |> Path.expand()
    _current_version = file |> Path.dirname() |> Path.basename()

    :ok
  end
end
