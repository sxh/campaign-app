# Architecture

Hexagonal architecture with three layers:

## Domain

- `opencode_session.gleam` — Pure URL construction. Defines the `OpenCodeState` type and functions `session_create_url/0` and `session_iframe_url/2`. No side effects, no dependencies.

## Adapters

- `electron_preload.gleam` — FFI bridge to Electron's `preload.js` via `contextBridge`. JavaScript-only; Erlang stubs panic.
- `obsidian_vault.gleam` — Configuration provider for the Obsidian vault path.

## Application

- `campaigner_app.gleam` — Lustre application (Model, Update, View). Session creation is injected as a dependency.
- `campaigner_app_main.gleam` — Entry point. Wires dependencies: `electron_preload.create_session_and_dispatch` is injected into `campaigner_app.init`.
