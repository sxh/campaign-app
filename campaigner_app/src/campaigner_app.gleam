import campaigner/system

pub fn main() {
  system.start()
  process_sleep_forever()
}

@external(erlang, "timer", "sleep")
fn timer_sleep(ms: Int) -> Nil

fn process_sleep_forever() {
  timer_sleep(1000 * 60 * 60)
  process_sleep_forever()
}
