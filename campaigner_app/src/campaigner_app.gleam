import gleam/io
import gleam/http/request
import gleam/http/response
import mist
import campaigner/vault
import campaigner/config
import campaigner/web/router
import campaigner/infrastructure/simplifile_adapter

pub fn main() {
  let cfg = config.load()
  let ctx = vault.Context(fs: simplifile_adapter.real_fs())
  
  io.println("Starting Campaigner App on http://localhost:8000")
  
  let assert Ok(_) =
    mist.new(handle_connection(_, cfg.vault_path, ctx))
    |> mist.port(8000)
    |> mist.start
  
  process_sleep_forever()
}

pub fn handle_connection(req: request.Request(t), vault_path: vault.VaultPath, ctx: vault.Context) -> response.Response(mist.ResponseData) {
  router.router(request.path_segments(req), vault_path, ctx)
  |> response.map(mist.Bytes)
}

@external(erlang, "timer", "sleep")
fn timer_sleep(ms: Int) -> Nil

fn process_sleep_forever() {
  timer_sleep(1000 * 60 * 60)
  process_sleep_forever()
}
