import gleam/io
import gleam/http/request
import gleam/http/response
import mist
import campaigner/vault
import campaigner/config
import campaigner/web/router
import campaigner/infrastructure/simplifile_adapter

pub fn start() {
  let cfg = config.load()
  let ctx = vault.Context(fs: simplifile_adapter.real_fs())
  
  io.println("Starting Campaigner App on http://localhost:8000")
  
  let assert Ok(_) =
    mist.new(fn(req) {
      router.router(request.path_segments(req), cfg.vault_path, ctx)
      |> response.map(mist.Bytes)
    })
    |> mist.port(8000)
    |> mist.start
  
  Nil
}
