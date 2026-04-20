pub fn coerce(a: a) -> b {
  do_coerce(a)
}

@external(erlang, "campaigner_app_ffi", "coerce")
fn do_coerce(a: a) -> b

pub fn silence_stdout(f: fn() -> a) -> a {
  do_silence_stdout(f)
}

@external(erlang, "campaigner_app_ffi", "silence_stdout")
fn do_silence_stdout(f: fn() -> a) -> a
