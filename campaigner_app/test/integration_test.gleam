import campaigner/system
import factories
import gleeunit/should

pub fn server_boot_test() {
  let logger = factories.logger_silent()

  // We test system.init to verify everything up to the mist.start call.
  // Starting a real mist server in a unit test is difficult because it 
  // doesn't return (it blocks).
  let res = system.init(logger)
  res |> should.be_ok()
}
