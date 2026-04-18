import campaigner/config
import campaigner/infrastructure/gemini_cli_adapter
import campaigner/infrastructure/simplifile_adapter
import campaigner/infrastructure/stdout_logger
import campaigner/ports/logger.{type Logger}
import campaigner/vault
import campaigner/web/router
import gleam/http/response
import mist

pub fn start() {
  let logger = stdout_logger.new()

  case init(logger) {
    Ok(#(cfg, ctx)) -> {
      logger.info("Starting Campaigner App on http://localhost:8000", [])

      let assert Ok(_) =
        mist.new(fn(req) {
          router.router(req, cfg.vault_path, ctx)
          |> response.map(mist.Bytes)
        })
        |> mist.port(8000)
        |> mist.start

      Nil
    }
    Error(err) -> {
      logger.error("Failed to start: " <> err, [])
      Nil
    }
  }
}

pub fn init(logger: Logger) -> Result(#(config.Config, vault.Context), String) {
  case config.load() {
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
