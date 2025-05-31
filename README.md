## tankyu_sha

> seeker in japaneesse

## How to run ?

- after setting up gleam, clone this repo
- run `gleam run` and follow through the CLI app

## Plan

I've updated the plan a bit here [plan.md](plan.md)

### initial interaction (OLD from here)

- give it some keywords
  - 10 minute delivery <- any point of interest, not necessarily specific
  - it can go and find some sources from the internet (web search ?)
  - we choose what sources to look at daily and collect info <- from 10 results,
    always look at these 3
  - newsa, newsb and some blog
- when to go and try collect info <- set a daily time or may be send info and
  collect anytime

### how it's going to function

- we run at n am everyday
- hit these sources
  - what are some challenges ?
  - sources will always have unstructured data <- A source may present info in a
    different way compared to B
  - even if we extract text, we don't really no how to find a common structure
  - RSS feed <- super structured, and usually available on most news sites and
    bigger blogs generally have as well
  - use stuff from web clippers ? <- can be used to extract clean text
  - hit APIs from sources <- issue is we need to have known sources and infra
    around it to interact
  - or write your own text sanitizer library and clean text extracted from
    websites
- collect data from the sites <- textual data
- sanitize maybe ? use any tool to clean text so that a human or any llm can
  read it
- either feed it to llm to collect summary or just send it as it is

### Things to look at

- find a browser than can be spwaned and closed fast
- how do we do background processing
- how do we process text to make it LLM usable
- what infra do we need around running LLM and making it generate summary
