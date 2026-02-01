// @generated from status_display.lustre
// @hash 36849ca7a0b7fd00fb3c06bd8d562554995e5d5a15e9b91e480bcc8aa1cae546
// DO NOT EDIT - regenerate with: gleam run -m lustre_template_gen

import lustre/element.{type Element, text}
import lustre/element/html
import lustre/attribute
import types.{type Status, Online, Away, Offline}

pub fn render(status: Status) -> Element(msg) {
  html.div([attribute.class("status-display")], [case status { Online -> html.span([attribute.class("online")], [text("Online")]) Away(reason) -> html.span([attribute.class("away")], [text("Away: "), text(reason)]) Offline -> html.span([attribute.class("offline")], [text("Offline")]) }])
}
