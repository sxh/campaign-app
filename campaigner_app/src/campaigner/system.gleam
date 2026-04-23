import campaigner/config
import campaigner/infrastructure/gemini_cli_adapter
import campaigner/infrastructure/simplifile_adapter
import campaigner/infrastructure/stdout_logger
import campaigner/ports/logger.{type Logger}
import campaigner/vault
import campaigner/web/router
import gleam/bytes_tree
import gleam/http/request
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
      let vp = case cfg {
        config.Config(vault_path: vp, opencode_hostname: _, opencode_port: _) -> vp
      }
      logger.info("Starting Campaigner App on port " <> int_to_string(port), [])

      mist.new(create_route_handler(vp, ctx))
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
  let cfg = config.from_vault_path(vault_path)
  create_route_handler_with_config(cfg, ctx, mist.read_body(
    _,
    1024 * 1024,
  ))
}

pub fn create_route_handler_with_config(
  cfg: config.Config,
  ctx: vault.Context,
  read_body: fn(request.Request(mist.Connection)) ->
    Result(request.Request(BitArray), any),
) {
  fn(req) { handle_request_with_config(req, cfg, ctx, read_body) }
}

pub fn create_route_handler_with_reader(
  config: config.Config,
  ctx: vault.Context,
  read_body: fn(request.Request(mist.Connection)) ->
    Result(request.Request(BitArray), any),
) {
  fn(req) { handle_request_with_config(req, config, ctx, read_body) }
}

pub fn handle_request(
  req: request.Request(c),
  vault_path: vault.VaultPath,
  ctx: vault.Context,
  read_body: fn(request.Request(c)) -> Result(request.Request(BitArray), any),
) -> response.Response(mist.ResponseData) {
  let cfg = config.from_vault_path(vault_path)
  handle_request_with_config(req, cfg, ctx, read_body)
}

pub fn handle_request_with_config(
  req: request.Request(c),
  config: config.Config,
  ctx: vault.Context,
  read_body: fn(request.Request(c)) -> Result(request.Request(BitArray), any),
) -> response.Response(mist.ResponseData) {
  case read_body(req) {
    Ok(req) -> {
      router.router_with_config(req, config.vault_path, ctx, config)
      |> response.map(mist.Bytes)
    }
    Error(_) -> {
      response.new(400)
      |> response.set_body(mist.Bytes(bytes_tree.from_string("Bad Request")))
    }
  }
}

@external(erlang, "erlang", "integer_to_binary")
fn int_to_string(i: Int) -> String
