export function create_session_and_dispatch(base_url, on_success, on_error) {
  window.opencodeAPI
    .createSession(base_url)
    .then(on_success)
    .catch((err) => {
      on_error(err.message ?? String(err));
    });
}
