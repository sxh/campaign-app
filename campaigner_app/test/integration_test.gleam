import campaigner/system
import factories
import gleeunit/should

pub fn server_boot_test() {
  let logger = factories.logger_silent()

  // Verify initialization.
  let res = system.init(logger)
  res |> should.be_ok()
}
