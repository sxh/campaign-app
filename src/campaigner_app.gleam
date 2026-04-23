import gleam/int
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub type Model {
  Model(count: Int)
}

pub type Msg {
  Increment
}

pub fn initial_model(_: Nil) -> Model {
  Model(count: 0)
}

pub fn update(model: Model, msg: Msg) -> Model {
  case msg {
    Increment -> Model(count: model.count + 1)
  }
}

pub fn view(model: Model) -> Element(Msg) {
  html.div([], [
    html.h1([], [html.text("Hello, World!")]),
    html.p([], [html.text("Count: " <> int.to_string(model.count))]),
    html.button([event.on_click(Increment)], [html.text("Increment")]),
  ])
}

pub fn view_text(model: Model) -> String {
  "Hello, World! Count: " <> int.to_string(model.count)
}
