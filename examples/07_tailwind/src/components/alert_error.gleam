// @generated from alert_error.lustre
// @hash baadaffd75fd56554e44d6f72c9a472546a5d770a2eeef14bd1dd231228932ac
// DO NOT EDIT - regenerate with: gleam run -m ghtml

import lustre/element.{type Element, text}
import lustre/element/html
import lustre/attribute

pub fn render(message: String) -> Element(msg) {
  html.div([attribute.class("rounded-md bg-red-50 p-4 mb-4")], [html.div([attribute.class("flex")], [html.div([attribute.class("ml-3")], [html.p([attribute.class("text-sm font-medium text-red-800")], [text(message)])])])])
}
