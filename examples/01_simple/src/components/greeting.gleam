// @generated from greeting.ghtml
// @hash 7e4e6544c70068bada96dd25120d671d94bf242aaf48658929f61af2943c8000
// DO NOT EDIT - regenerate with: gleam run -m ghtml

import lustre/attribute
import lustre/element.{type Element, text}
import lustre/element/html

pub fn render(name: String) -> Element(msg) {
  html.div([attribute.class("greeting")], [
    html.h1([], [text("Hello, "), text(name), text("!")]),
    html.p([], [text("Welcome to ghtml templates.")]),
  ])
}
