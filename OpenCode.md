# OpenCode Guidelines for tankyu-sha

This document provides guidelines for AI agents contributing to this repository.

## General Principles

- Adhere to existing code style and patterns.
- Use the recommended tools for formatting and linting.
- Write clear, concise, and well-typed code where applicable.

## Build, Lint, Test Commands

- Build Gleam: `gleam build`
- Run Gleam tests: `gleam test`
- Format Gleam code: `gleam format`
- Format & Lint JS/TS/JSON/etc: `bunx biome check --apply`
- Format JS/TS/JSON/etc: `bunx biome format --write`

## Code Style Guidelines

- **Formatting:** Use `gleam format` and `bunx biome format --write`.
- **Naming:** Follow language conventions.
- **Types:** Respect type annotations (Gleam, TS) and specs (Elixir).
- **Error Handling:** Use idiomatic patterns (Gleam `Result`, Elixir
  `{:ok, :error}`, JS/TS errors).
- **Imports:** Be explicit where required (Gleam) and follow conventions.

