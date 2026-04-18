import gleam/io
import gleam/http/request
import gleam/http/response
import mist
import campaigner/vault
import campaigner/config
import campaigner/web/router

pub fn main() {
  let cfg = config.load()
  let ctx = vault.Context(fs: vault.real_fs())
  
  io.println("Starting Campaigner App on http://localhost:8000")
  
  let assert Ok(_) =
    mist.new(fn(req) {
      router.router(request.path_segments(req), cfg.vault_path, ctx)
      |> response.map(mist.Bytes)
    })
    |> mist.port(8000)
    |> mist.start
  
  process_sleep_forever()
}

@external(erlang, "timer", "sleep")
fn timer_sleep(ms: Int) -> Nil

fn process_sleep_forever() {
  timer_sleep(1000 * 60 * 60)
  process_sleep_forever()
}
