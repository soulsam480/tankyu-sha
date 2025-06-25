# AGENTS.md

# Tankyu Sha

## Project Overview

1. tankyu-sha is is an AI assisted personal digest tool.
2. the end goal is to keep an eye over a bunch of stuff over the internet
   without having to go to the websites.

The overral system can be seen here [plan.md](plan.md), though it's not updated
in a while. will fix that

## Key Gleam Documentation References as the project primarily uses the Gleam programming language

### Language Tour

For comprehensive Gleam language features, refer to `@gleam-tour.md`. This
covers:

- Basic syntax and types (Int, Float, String, Bool, List)
- Functions, pipelines, and higher-order functions
- Pattern matching and case expressions
- Custom types and records
- Error handling with Result types
- Standard library modules (list, result, dict, option)

### Writing Gleam Guide

For project structure and development workflow, refer to `@writing-gleam.md`.
This covers:

- Creating and organizing Gleam projects
- Using the `gleam` build tool
- Managing dependencies with Hex packages
- Testing with gleeunit
- Building and running projects

## Gleam-Specific Guidelines

### Code Style

- Use snake_case for variables and functions
- Use PascalCase for types and constructors
- Prefer piping (`|>`) for function composition
- Use pattern matching instead of if/else where possible
- Leverage the Result type for error handling instead of exceptions
- when there's is an error for unused imports, just remove those lines diretly

### Project Structure

```
src/
├── app/
│   ├── controllers/
│   │   ├── source_runs.gleam
│   │   ├── task_runs.gleam
│   │   └── tasks.gleam
│   ├── legacy.gleam
│   ├── router.gleam
│   └── router_context.gleam
├── background_process/
│   ├── cleaner.gleam
│   ├── executor.gleam
│   ├── ingestor.gleam
│   ├── scheduler.gleam
│   └── supervisor.gleam
├── content/
│   ├── feed_source.gleam
│   ├── news_source.gleam
│   ├── runner.gleam
│   └── search_source.gleam
├── ffi/
│   ├── ai.ex
│   ├── ai.gleam
│   ├── dom.ex
│   ├── dom.gleam
│   ├── llmchain.ex
│   ├── llmchain.gleam
│   ├── sqlite.ex
│   ├── sqlite.gleam
│   └── sqlite_downloader.ex
├── lib/
│   ├── error.gleam
│   ├── logger.gleam
│   ├── migrator.gleam
│   └── utils.gleam
├── models/
│   ├── document.gleam
│   ├── source.gleam
│   ├── source_run.gleam
│   ├── task.gleam
│   └── task_run.gleam
├── services/
│   ├── browser.gleam
│   └── internet_search.gleam
└── tankyu_sha.gleam

priv/
├── lib/
│   ├── content_to_markdown.mjs
│   └── error.mjs
├── migrations/
│   ├── 20250607173430_add_documents.sql
│   ├── 20250607173444_add_tasks.sql
│   ├── 20250607181632_add_sources.sql
│   ├── 20250607184851_add_task_runs.sql
│   └── 20250608082155_add_source_runs.sql
├── modules/
│   ├── linkedin-url-info.mjs
│   ├── linkedin.mjs
│   ├── news.mjs
│   ├── search.mjs
│   └── source.mjs
├── index.d.ts
└── run.mjs
```

### Performance Considerations

- Gleam lists are linked lists - prepending is O(1), appending is O(n)
- Use tail recursion for loops to avoid stack overflow
- Consider using `dict` for lookups instead of repeated list searches
- The `set` type (from `gleam/set`) is useful for membership tests

## AI Assistance Guidelines

When helping with Tankyu Sha stuff:

1. **Start Simple**: Begin with a working solution for the example, then handle
   the full input
2. **Parse First**: Focus on correctly parsing the input before solving the
   problem
3. **Use Types**: Define custom types to model the problem domain clearly
4. **Functional Style**: Embrace immutability and functional patterns
5. **Error Handling**: Use Result types and handle all error cases explicitly

## Common Gotchas

1. **Division by zero** returns 0 in Gleam, not an error
2. **String concatenation** uses `<>` operator, not `+`
3. **Equality** is structural, works on any type with `==`
4. **No early returns** - use pattern matching and Result types
5. **No null** - use Option type for optional values
6. **No exceptions** - use Result type for fallible operations

## Memory: Gleam Keywords

- You can use the `todo` keyword when something is not done yet

Remember to refer to the documentation files for
[detailed language features](/gleam_tour.md) and
[project setup instructions](/writing_gleam.md).
