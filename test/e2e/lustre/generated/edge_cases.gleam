// @generated from special.ghtml
// @hash 4d79d345693983454658df55cf93ee86d53253a14300fb3a659b16dec5ae18ec
// DO NOT EDIT - regenerate with: gleam run -m ghtml

import lustre/attribute
import lustre/element.{type Element, text}
import lustre/element/html

pub fn render() -> Element(msg) {
  html.div([], [
    html.br([]),
    html.input([attribute.type_("text")]),
    html.span([], [text("Text with {escaped braces}")]),
  ])
}
