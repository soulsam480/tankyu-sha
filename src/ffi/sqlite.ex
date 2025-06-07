defmodule Sqlite do
  def open(path) do
    case Exqlite.Basic.open(path) do
      {:ok, conn} ->
        Exqlite.Basic.enable_load_extension(conn)
        Exqlite.Basic.load_extension(conn, SqliteVec.path())
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
    end
  end

  def bind(val) do
    val
  end

  def bind_nil() do
    nil
  end
end

