# Campaigner App

A desktop application built with Gleam, Lustre, and Electron that embeds an OpenCode session iframe alongside an Obsidian vault management pane.

## OpenCode Integration Reference

This app emulates the [opencode-obsidian](https://github.com/mtymek/opencode-obsidian) plugin. The plugin is configured correctly in the local Obsidian instance and connects via:

```
http://127.0.0.1:14096/{base64_encoded_vault_path}/session
```

The vault path is: `/Users/steve.hayes/Library/Mobile Documents/iCloud~md~obsidian/Documents/ForgottenRealmsVault`

NOTE: The vault path has NO trailing slash. Base64 encoding `"/Users/steve.hayes/Library/Mobile Documents/iCloud~md~obsidian/Documents/ForgottenRealmsVault"` (without trailing slash) produces:
`L1VzZXJzL3N0ZXZlLmhheWVzL0xpYnJhcnkvTW9iaWxlIERvY3VtZW50cy9pQ2xvdWR+bWR+b2JzaWRpYW4vRG9jdW1lbnRzL0ZvcmdvdHRlblJlYWxtc1ZhdWx0`

The full iframe URL is:
```
http://127.0.0.1:14096/L1VzZXJzL3N0ZXZlLmhheWVzL0xpYnJhcnkvTW9iaWxlIERvY3VtZW50cy9pQ2xvdWR+bWR+b2JzaWRpYW4vRG9jdW1lbnRzL0ZvcmdvdHRlblJlYWxtc1ZhdWx0/session
```

CRITICAL: There is no JSON API. The server returns HTML at this URL. The `<iframe>` loads this URL directly — no POST, no fetch, no session creation API call. The response IS the iframe content. If the HTML returned does not contain the vault path string "ForgottenRealmsVault", the URL is wrong.

## Stack

- **Gleam** (statically typed, BEAM language) compiling to **JavaScript** for the renderer, **Erlang** for tests and coverage
- **Lustre** (Elm-architecture UI framework for Gleam)
- **Electron** (desktop shell)
- **Custom bundler** (`scripts/build.js`) — resolves and copies compiled ES modules to `public/`
- **Gleeunit** (test framework)
- **Erlang `cover` tool** via custom escript for line coverage (95% threshold)

## Architecture

Hexagonal architecture:

- **Domain**: `opencode_session.gleam` — pure URL construction logic, no side effects
- **Adapters**: `electron_preload_ffi.mjs` — FFI bridge to Electron's preload API; `obsidian_vault.gleam` — vault path provider
- **Application**: `campaigner_app.gleam` — Lustre init/update/view that builds the iframe URL directly from the vault path

## Key Rules

1. **Test first** — Write the test before the code. All tests must pass before commit.
2. **Coverage >= 95%** — Line coverage enforced via Erlang `cover` tool. Function coverage on compiled Gleam JS is meaningless and is NOT enforced.
3. **No dependency warnings** — `build/packages/` warnings are filtered out; project source warnings are fatal.
4. **Smoke test** — Precommit hook must build the JS target and verify all referenced files exist.
5. **No skipped tests** — Never use `.skip()` or equivalent.

## Commands

```bash
npm run build    # gleam build --target javascript && node scripts/build.js
npm start        # build + electron .
npm run test     # gleam test
npm run lint     # gleam format --check src test
npm run format   # gleam format src test
```

## Project Structure

```
src/
  campaigner_app.gleam         # Main Lustre app (init/update/view)
  campaigner_app_main.gleam    # Entry point, wires dependencies
  opencode_session.gleam       # Domain: URL construction
  obsidian_vault.gleam         # Adapter: vault path
  electron_preload_ffi.mjs     # JS FFI implementation
electron/
  main.cjs                     # Electron main process
  preload.js                   # Preload script (contextBridge)
test/
  campaigner_app_test.gleam
  opencode_session_test.gleam
  obsidian_vault_test.gleam
scripts/
  build.js                     # Custom module bundler
  coverage.escript             # Erlang coverage reporter
```
