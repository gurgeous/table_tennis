# Purpose

TableTennis is a popular ruby gem for rendering ANSI-colored tables from csv-like rows (hash-ish objects). Beauty > performance, but keep small-table latency snappy.

# Key flow

- Public API: `TableTennis.new` -> `TableTennis::Table` (`lib/table_tennis/table.rb`).
- Pipeline: `Format` -> `Layout` -> `Painter` -> `Render` (`lib/table_tennis/stage/*.rb`).
- Data model: `TableData`, `Column`, `Row` (`lib/table_tennis/table_data.rb`, `lib/table_tennis/column.rb`, `lib/table_tennis/row.rb`).
- Config/theming: `Config`, `Theme`, `Util::Colors/Console/Strings/Termbg` (`lib/table_tennis/config.rb`, `lib/table_tennis/theme.rb`, `lib/table_tennis/util/*`).

# dev (prefer `just`)

- `just test`
- `just lint` / `just format`
- `just check`

# Style/conventions

- Defaults and validation live in `Config` (`MagicOptions`).
- Rendering cost is mostly in `Stage::Render` (ANSI/string work); memoization via `MemoWise` is used in hot paths.
- Prefer short methods, short variable names, and comment lightly when code is complex
- Ruby one-liners are find and even preferred for trivial methods
