// @generated from basic.ghtml
// @hash 2293fbf6dab4f4d49d295fb269d6c2911afcec1ee5463d2c2e5b3679593d4aab
// DO NOT EDIT - regenerate with: gleam run -m ghtml

import lustre/attribute
import lustre/element.{type Element, text}
import lustre/element/html

pub fn render(message: String) -> Element(msg) {
  html.div([attribute.class("greeting")], [html.p([], [text(message)])])
}
