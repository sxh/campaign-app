# Campaigner App

A desktop application built with Gleam, Lustre, and Electron that embeds an OpenCode session iframe alongside an Obsidian vault management pane.

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
- **Adapters**: `electron_preload.gleam` — FFI bridge to Electron's preload API; `obsidian_vault.gleam` — vault path provider
- **Application**: `campaigner_app.gleam` — Lustre init/update/view wired with dependency injection (session creation function is injected)

## Key Rules

1. **Test first** — Write the test before the code. All tests must pass before commit.
2. **Coverage >= 95%** — Line coverage enforced via Erlang `cover` tool. Function coverage on compiled Gleam JS is meaningless and is NOT enforced.
3. **No dependency warnings** — `build/packages/` warnings are filtered out; project source warnings are fatal.
4. **Smoke test** — Precommit hook must build the JS target and verify all referenced files exist.
5. **No skipped tests** — Never use `.skip()` or equivalent.
6. **Dependency injection** — All side-effectful functions are injected; no hardcoded FFI calls in domain/application logic.

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
  electron_preload.gleam       # Adapter: FFI to preload.js
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
