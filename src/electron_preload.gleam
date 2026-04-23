@target(javascript)
@external(javascript, "./electron_preload_ffi.mjs", "create_session_and_dispatch")
pub fn create_session_and_dispatch(
  base_url: String,
  on_success: fn(String) -> Nil,
  on_error: fn(String) -> Nil,
) -> Nil

@target(erlang)
pub fn create_session_and_dispatch(
  _base_url: String,
  _on_success: fn(String) -> Nil,
  _on_error: fn(String) -> Nil,
) -> Nil {
  panic as "create_session_and_dispatch is only available on JavaScript target"
}
