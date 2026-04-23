pub fn session_iframe_url(encoded_path: String) -> String {
  "http://127.0.0.1:14096/" <> encoded_path <> "/session"
}
