import components/greeting
import lustre
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn main() {
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

type Model {
  Model(name: String)
}

fn init(_flags) -> Model {
  Model(name: "World")
}

type Msg {
  UserUpdatedName(String)
}

fn update(_model: Model, msg: Msg) -> Model {
  case msg {
    UserUpdatedName(name) -> Model(name: name)
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([], [
    html.input([event.on_input(UserUpdatedName)]),
    greeting.render(model.name),
  ])
}
