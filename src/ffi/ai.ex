defmodule Ai do
  def find_source_type(dict, model \\ "deepseek-r1:7b") do
    client = Ollama.init(receive_timeout: 60_000 * 4)

    Ollama.completion(client,
      model: model,
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
  end

  def get_feed_analysis(posts, model \\ "deepseek-r1:7b") do
    client = Ollama.init(receive_timeout: 60_000 * 4)

    Ollama.completion(client,
      model: model,
      prompt:
        "You're an expert information analyst that can give summary of content posted by people/companies on the internet.
        This content can be anything from their future bussiness plans, announcing something new, landing a new job, announcing
        a big business deal or something along these lines. You have to read and understand the goal from a list of their content
        and prepare an analysis of what they're trying to do. It has to be concise. The information is as follows:

        " <> posts
    )
  end

  def get_news_summary(article, model \\ "deepseek-r1:7b") do
    client = Ollama.init(receive_timeout: 60_000 * 4)

    Ollama.completion(client,
      model: model,
      prompt: "You are an analyst trained to create accessible summaries of complex news content.

        Summarize the following article for a general audience. Your summary should:
        - Keep the entire summary around 150-200 words
        - Throw in some tables, bullet points or any sort of formatting ONLY when necessary to make it easily readable
        - Be written in clear, plain language
        - Avoid jargon, speculation, or exaggeration
        - Capture only the most important facts or arguments
        - Avoid quoting or citing specific people unless necessary
        - If a claim is disputed, mention that it's disputed. Avoid emotionally charged language or analogies unless directly quoted and clearly attributed.
        - AVOID PUTTING ADDITIONAL HEADERS_FOOTERS WITH THE SUMMARY e.g. Here's a summary of x
        - The summary should be in GitHub flavored markdown

        Use this example as a format:

        - The report found that only 40% of the budget was spent as planned.
        - Experts believe delays were caused by supply chain issues.
        - The government has not responded to the findings yet.

        Now summarize the article below with additional instructions in the end if present:
" <> article
    )
  end

  def embed(content, model) do
    client = Ollama.init(receive_timeout: 60_000 * 4)

    Ollama.embed(client, model: model, input: content)
  end
end
