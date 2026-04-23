export function encode_base64(str) {
  return window.opencodeAPI.encodeBase64(str);
}

export function create_session_and_dispatch(base_url, directory, on_success, on_error) {
  window.opencodeAPI
    .createSession(base_url, directory)
    .then(on_success)
    .catch((err) => {
      on_error(err.message ?? String(err));
    });
}
