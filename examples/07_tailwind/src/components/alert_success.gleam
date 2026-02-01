// @generated from alert_success.lustre
// @hash 92b64aa929921e55ca9af9965c996b0c10e5edc74e35dfd4a4f39b9f78b41042
// DO NOT EDIT - regenerate with: gleam run -m ghtml

import lustre/element.{type Element, text}
import lustre/element/html
import lustre/attribute

pub fn render(message: String) -> Element(msg) {
  html.div([attribute.class("rounded-md bg-green-50 p-4 mb-4")], [html.div([attribute.class("flex")], [html.div([attribute.class("ml-3")], [html.p([attribute.class("text-sm font-medium text-green-800")], [text(message)])])])])
}
