import gleam/http/request
import gleam/http/response
import mist
import campaigner/vault
import campaigner/config
import campaigner/web/router
import campaigner/infrastructure/simplifile_adapter
import campaigner/infrastructure/stdout_logger

pub fn start() {
  let logger = stdout_logger.new()
  
  case config.load() {
    Ok(cfg) -> {
      let ctx = vault.Context(fs: simplifile_adapter.real_fs(), logger: logger)
      
      logger.info("Starting Campaigner App on http://localhost:8000")
      
      let assert Ok(_) =
        mist.new(fn(req) {
          router.router(request.path_segments(req), cfg.vault_path, ctx)
          |> response.map(mist.Bytes)
        })
        |> mist.port(8000)
        |> mist.start
      
      Nil
    }
    Error(err) -> {
      let msg = case err {
        config.EnvironmentVariableMissing(name) -> "Environment variable missing: " <> name
        config.InvalidConfigPath(reason) -> "Invalid configuration: " <> reason
      }
      logger.error("Failed to start: " <> msg)
      Nil
    }
  }
}
