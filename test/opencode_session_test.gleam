import gleam/bit_array
import gleeunit
import gleeunit/should
import obsidian_vault
import opencode_session

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn session_iframe_url_includes_encoded_vault_path_test() {
  let encoded = "L3VzZXJzL3Rlc3QvdmF1bHQ"
  let result = opencode_session.session_iframe_url(encoded)
  result
  |> should.equal("http://127.0.0.1:14096/L3VzZXJzL3Rlc3QvdmF1bHQ/session")
}

pub fn session_iframe_url_uses_correct_vault_encoding_test() {
  let path = obsidian_vault.vault_path()
  let expected_encoded =
    "L1VzZXJzL3N0ZXZlLmhheWVzL0xpYnJhcnkvTW9iaWxlIERvY3VtZW50cy9pQ2xvdWR+bWR+b2JzaWRpYW4vRG9jdW1lbnRzL0ZvcmdvdHRlblJlYWxtc1ZhdWx0"
  opencode_session.session_iframe_url(bit_array.base64_encode(
    bit_array.from_string(path),
    False,
  ))
  |> should.equal("http://127.0.0.1:14096/" <> expected_encoded <> "/session")
}
