// @generated from form.lustre
// @hash f48d1d710b41aaa86f43b5d85995f5ad9656293dfd2cb9b044b9bd31dd481fca
// DO NOT EDIT - regenerate with: gleam run -m ghtml

import lustre/element.{type Element, text}
import lustre/element/html
import lustre/attribute
import lustre/event

pub fn render(value: String, on_input: fn(String) -> msg, on_click: fn() -> msg, on_focus: fn() -> msg, on_blur: fn() -> msg) -> Element(msg) {
  html.div([attribute.class("form")], [html.input([attribute.type_("text"), attribute.class("input"), attribute.value(value), attribute.placeholder("Type something..."), event.on_input(on_input), event.on_focus(on_focus()), event.on_blur(on_blur())]), html.button([attribute.class("btn"), event.on_click(on_click())], [text("Submit")])])
}
