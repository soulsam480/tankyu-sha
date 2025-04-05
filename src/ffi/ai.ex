defmodule Ai do
  def find_source_type(dict) do
    client = Ollama.init()

    {:ok, res} =
      Ollama.completion(client,
        model: "llama3.2:3b",
        prompt:
          "I have the following information from the internet. Based on the data provided can you guess the
        type of the website this link can lead to ? The categories are 
        1. Feed \( This can be any profile feed, with few cards\)
        2. News \( This can be any news website, with few articles\)
        3. Blog \( This can be any blog website, with articles\)

        The data is as follows:

        " <> JSON.encode!(dict) <> "
        You don't need to explain anything, just give me the result"
      )

    res
  end
end
