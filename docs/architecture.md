# Architecture

Hexagonal architecture with three layers:

## Domain

- `opencode_session.gleam` — Pure URL construction. Defines the `OpenCodeState` type and function `opencode_iframe_url/1`. No side effects, no dependencies.

## Adapters

- `electron_preload_ffi.mjs` — FFI bridge to Electron's `preload.js` via `contextBridge`. JavaScript-only; Erlang stubs panic.
- `obsidian_vault.gleam` — Configuration provider for the Obsidian vault path.

## Application

- `campaigner_app.gleam` — Lustre application (Model, Update, View). Builds the iframe URL directly from the vault path.
- `campaigner_app_main.gleam` — Entry point. Calls `obsidian_vault.vault_path()`, base64-encodes it via FFI, and starts the Lustre app.
