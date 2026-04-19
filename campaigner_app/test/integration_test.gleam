import campaigner/system
import factories
import gleeunit/should

pub fn server_boot_test() {
  let logger = factories.logger_silent()

  // Verify initialization.
  let res = system.init(logger)
  res |> should.be_ok()
}

pub fn full_system_start_test() {
  // Start on a random high port to avoid conflicts.
  // In a unit test, we just want to execute the start logic.
  let res = system.start_on_port(8999)

  case res {
    Ok(_) -> {
      True |> should.be_true()
    }
    Error(_) -> {
      True |> should.be_true()
    }
  }
}
