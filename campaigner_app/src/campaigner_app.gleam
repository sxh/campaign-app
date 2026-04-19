import campaigner/system

pub fn main() {
  let _ = run()
  process_sleep_forever()
}

pub fn run() {
  system.start()
}

@external(erlang, "timer", "sleep")
fn timer_sleep(ms: Int) -> Nil

fn process_sleep_forever() {
  timer_sleep(1000 * 60 * 60)
  process_sleep_forever()
}
