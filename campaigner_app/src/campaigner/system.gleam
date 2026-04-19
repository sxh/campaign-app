import campaigner/config
import campaigner/infrastructure/gemini_cli_adapter
import campaigner/infrastructure/simplifile_adapter
import campaigner/infrastructure/stdout_logger
import campaigner/ports/logger.{type Logger}
import campaigner/vault
import campaigner/web/router
import gleam/http/response
import gleam/result
import mist

pub fn start() -> Result(Nil, String) {
  start_on_port(8000)
}

pub fn start_on_port(port: Int) -> Result(Nil, String) {
  let logger = stdout_logger.new()
  start_with_dependencies(port, logger, config.load)
}

pub fn start_with_dependencies(
  port: Int,
  logger: Logger,
  load_config: fn() -> Result(config.Config, config.ConfigError),
) -> Result(Nil, String) {
  case init_with_config_loader(logger, load_config) {
    Ok(#(cfg, ctx)) -> {
      logger.info("Starting Campaigner App on port " <> int_to_string(port), [])

      mist.new(create_route_handler(cfg.vault_path, ctx))
      |> mist.port(port)
      |> mist.start
      |> result.replace(Nil)
      |> result.replace_error("Failed to start server")
    }
    Error(err) -> {
      logger.error("Failed to start: " <> err, [])
      Error(err)
    }
  }
}

pub fn init(logger: Logger) -> Result(#(config.Config, vault.Context), String) {
  init_with_config_loader(logger, config.load)
}

pub fn init_with_config_loader(
  logger: Logger,
  load_config: fn() -> Result(config.Config, config.ConfigError),
) -> Result(#(config.Config, vault.Context), String) {
  case load_config() {
    Ok(cfg) -> {
      let ctx =
        vault.Context(
          fs: simplifile_adapter.real_fs(),
          logger: logger,
          chat: gemini_cli_adapter.new(),
          timeout_ms: 5000,
        )
      Ok(#(cfg, ctx))
    }
    Error(err) -> {
      let msg = case err {
        config.EnvironmentVariableMissing(name) ->
          "Environment variable missing: " <> name
        config.InvalidConfigPath(reason) -> "Invalid configuration: " <> reason
      }
      Error(msg)
    }
  }
}

pub fn create_route_handler(vault_path: vault.VaultPath, ctx: vault.Context) {
  fn(req) {
    router.router(req, vault_path, ctx)
    |> response.map(mist.Bytes)
  }
}

// Internal helpers to avoid extra dependencies for basic logic
@external(erlang, "erlang", "integer_to_binary")
fn int_to_string(i: Int) -> String
// Removed result_map_error as it's unused
