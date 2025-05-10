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

  def get_feed_analysis(posts) do
    client = Ollama.init()

    {:ok, res} =
      Ollama.completion(client,
        model: "llama3.2:3b",
        prompt:
          "You're an expert information analyst that can give summary of content posted by people/companies on the internet.
        This content can be anything from their future bussiness plans, announcing something new, landing a new job, announcing
        a big business deal or something along these lines. You have to read and understand the goal from a list of their content
        and prepare an analysis of what they're trying to do. It has to be concise. The information is as follows:

        " <> posts
      )

    res
  end
end
