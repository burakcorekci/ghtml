// @generated from sl_checkbox.lustre
// @hash 710a43c7e45318844698eeb5c436f9b73db3e6cc5aa72b7797a1bfba0cf9ed26
// DO NOT EDIT - regenerate with: gleam run -m lustre_template_gen

import lustre/element.{type Element, text, element}
import lustre/attribute
import lustre/event
import gleam/dynamic/decode

pub fn render(label: String, is_checked: Bool, on_change: decode.Decoder(msg)) -> Element(msg) {
  case is_checked { True -> element("sl-checkbox", [attribute.attribute("checked", ""), event.on("sl-change", on_change)], [text(label)]) False -> element("sl-checkbox", [event.on("sl-change", on_change)], [text(label)]) }
}
