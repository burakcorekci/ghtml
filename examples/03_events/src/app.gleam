import components/counter
import components/form
import components/search_input
import lustre
import lustre/element.{type Element}
import lustre/element/html

pub fn main() {
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

type Model {
  Model(count: Int, query: String, form_value: String, is_focused: Bool)
}

fn init(_flags) -> Model {
  Model(count: 0, query: "", form_value: "", is_focused: False)
}

type Msg {
  Increment
  Decrement
  UpdateQuery(String)
  UpdateFormValue(String)
  ClickSubmit
  FocusInput
  BlurInput
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    Increment -> Model(..model, count: model.count + 1)
    Decrement -> Model(..model, count: model.count - 1)
    UpdateQuery(q) -> Model(..model, query: q)
    UpdateFormValue(v) -> Model(..model, form_value: v)
    ClickSubmit -> Model(..model, form_value: "")
    FocusInput -> Model(..model, is_focused: True)
    BlurInput -> Model(..model, is_focused: False)
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([], [
    html.h1([], [html.text("Events Example")]),
    // Pattern 2: Function Call
    html.div([attribute.class("section")], [
      html.h2([], [
        html.text("Pattern 2: Function Call (@click={handler()})"),
      ]),
      html.p([], [
        html.text(
          "Use this pattern when you don't need event data. The handler is invoked directly.",
        ),
      ]),
      counter.render(model.count, fn() { Increment }, fn() { Decrement }),
    ]),
    // Pattern 1: Function Reference
    html.div([attribute.class("section")], [
      html.h2([], [
        html.text("Pattern 1: Function Reference (@input={handler})"),
      ]),
      html.p([], [
        html.text(
          "Use this pattern when Lustre needs to extract and pass event data to your handler.",
        ),
      ]),
      search_input.render(model.query, UpdateQuery),
      html.p([attribute.class("result")], [
        html.text("You typed: " <> model.query),
      ]),
    ]),
    // Multiple Event Types
    html.div([attribute.class("section")], [
      html.h2([], [html.text("Multiple Event Types")]),
      html.p([], [
        html.text(
          "Combining both patterns: @input uses function reference, @click/@focus/@blur use function calls.",
        ),
      ]),
      form.render(
        model.form_value,
        UpdateFormValue,
        fn() { ClickSubmit },
        fn() { FocusInput },
        fn() { BlurInput },
      ),
      html.p([attribute.class("status")], [
        html.text(case model.is_focused {
          True -> "Input is focused"
          False -> "Input is not focused"
        }),
      ]),
    ]),
  ])
}

import lustre/attribute
