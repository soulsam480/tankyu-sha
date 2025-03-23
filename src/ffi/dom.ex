defmodule Dom do
  # gleam: services/dom.gleam
  def find_links(html) do
    {:ok, document} = Floki.parse_document(html)

    document
    |> Floki.find(".result")
    |> Enum.map(fn el ->
      link = el |> Floki.find("a") |> Floki.attribute("href") |> List.first()

      text =
        el
        |> Floki.find("a")
        |> Floki.text()
        |> String.replace(~r/\n/, "")
        |> String.replace(~r/\s+/, " ")

      %{link: link, title: text}
    end)
  end
end
