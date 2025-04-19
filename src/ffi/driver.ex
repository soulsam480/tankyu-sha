defmodule Driver do
  def load(url) do
    {:ok, browser} =
      Playwright.launch(:chromium, %{
        executable_path: "/Applications/Chromium.app/Contents/MacOS/Chromium"
      })

    page =
      browser |> Playwright.Browser.new_page()

    page
    |> Playwright.Page.goto(url)

    page |> Playwright.Page.wait_for_load_state()

    page |> Playwright.Page.title()
  end
end
