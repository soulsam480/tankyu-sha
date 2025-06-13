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

    # TODO: wrap result
    res
  end

  def get_feed_analysis(posts) do
    client = Ollama.init()

    {:ok, res} =
      Ollama.completion(client,
        model: "deepseek-r1:7b",
        prompt:
          "You're an expert information analyst that can give summary of content posted by people/companies on the internet.
        This content can be anything from their future bussiness plans, announcing something new, landing a new job, announcing
        a big business deal or something along these lines. You have to read and understand the goal from a list of their content
        and prepare an analysis of what they're trying to do. It has to be concise. The information is as follows:

        " <> posts
      )

    # TODO: wrap result
    res
  end

  def get_news_summary(article) do
    client = Ollama.init()

    {:ok, res} =
      Ollama.completion(client,
        # model: "deepseek-r1:7b",
        model: "llama3.2:3b",
        prompt:
          "You are an analyst trained to create accessible summaries of complex news content.

        Summarize the following article for a general audience. Your summary should:
        - Use 4–7 concise bullet points
        - Be written in clear, plain language
        - Avoid jargon, speculation, or exaggeration
        - Capture only the most important facts or arguments
        - Avoid quoting or citing specific people unless necessary
        - If a claim is disputed, mention that it's disputed. Avoid emotionally charged language or analogies unless directly quoted and clearly attributed.

        Use this example as a format:

        - The report found that only 40% of the budget was spent as planned.
        - Experts believe delays were caused by supply chain issues.
        - The government has not responded to the findings yet.

        Now summarize the article below:
" <> article
      )

    # TODO: wrap result
    res
  end

  def embed(content, model) do
    client = Ollama.init()

    Ollama.embed(client, model: model, input: content)
  end
end
