defmodule Sqlite do
  @moduledoc """
  taken from https://github.com/joelpaulkoch/sqlite_vec/blob/main/lib/sqlite_vec.ex
  """

  def open(path) do
    download_ext()

    case Exqlite.Basic.open(path) do
      {:ok, conn} ->
        Exqlite.Basic.enable_load_extension(conn)
        Exqlite.Basic.load_extension(conn, ext_path())
        {:ok, %{conn: conn}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def close(%{conn: conn}) do
    case Exqlite.Basic.close(conn) do
      :ok -> {:ok, nil}
      {:error, reason} -> {:error, reason}
    end
  end

  def exec(%{conn: conn}, query, params) do
    case Exqlite.Basic.exec(conn, query, params) do
      {:ok, _, res, _} -> {:ok, res}
      {:error, reason} -> {:error, reason}
      e -> {:error, e}
    end
  end

  def bind(val) do
    val
  end

  def bind_nil() do
    nil
  end

  def ext_path do
    Application.app_dir(:tankyu_sha, "sqlite_vec/0.1.6/vec0")
  end

  def download_ext do
    if !File.exists?(ext_path()) do
      File.mkdir_p(Path.dirname(ext_path()))
    end

    SqliteDownloader.download(Path.dirname(ext_path()))
  end

  # merge rows with columns
  def zip(columns, rows) do
    Enum.zip(columns, rows) |> Map.new()
  end
end
