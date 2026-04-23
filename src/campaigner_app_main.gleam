import campaigner_app
import lustre

pub fn main() {
  let app =
    lustre.application(
      campaigner_app.init,
      campaigner_app.update,
      campaigner_app.view,
    )
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
