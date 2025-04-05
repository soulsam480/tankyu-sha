defmodule Dom do
  # gleam: services/dom.gleam
  def find_links(html) do
    {:ok, document} = Floki.parse_document(html)

    document
    |> Floki.find(".result")
    |> Enum.with_index(1)
    |> Enum.map(fn {el, index} ->
      link = el |> Floki.find("a.result__url") |> Floki.attribute("href") |> List.first()

      title =
        el
        |> Floki.find("a")
        |> Floki.text()
        |> String.replace(~r/\n/, "")
        |> String.replace(~r/\s+/, " ")

      description =
        el
        |> Floki.find(".result__snippet")
        |> Floki.text()
        |> String.replace(~r/\n/, "")
        |> String.replace(~r/\s+/, " ")

      %{link: link, title: title, id: index |> Integer.to_string(), description: description}
    end)
  end
end
