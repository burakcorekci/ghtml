// @generated from sl_input.lustre
// @hash d7df78355ff748a1bd1b3e57bd02a49f5538adf694421e426254c0e0febf7109
// DO NOT EDIT - regenerate with: gleam run -m ghtml

import lustre/element.{type Element, element}
import lustre/attribute
import lustre/event
import gleam/dynamic/decode

pub fn render(value: String, label: String, placeholder: String, on_input: decode.Decoder(msg)) -> Element(msg) {
  element("sl-input", [attribute.value(value), attribute.attribute("label", label), attribute.placeholder(placeholder), event.on("sl-input", on_input)], [])
}
