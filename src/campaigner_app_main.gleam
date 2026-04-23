import campaigner_app
import lustre

pub fn main() {
  let app =
    lustre.simple(
      campaigner_app.initial_model,
      campaigner_app.update,
      campaigner_app.view,
    )
  let assert Ok(_) = lustre.start(app, onto: "#app", with: Nil)
  Nil
}
