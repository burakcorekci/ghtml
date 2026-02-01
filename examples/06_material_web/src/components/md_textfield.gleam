// @generated from md_textfield.lustre
// @hash 6dbe33e7476a97cb0a21a5ed899847608baa77a2f67f478f91910f1367c4e0da
// DO NOT EDIT - regenerate with: gleam run -m ghtml

import lustre/element.{type Element, element}
import lustre/attribute
import lustre/event

pub fn render(value: String, label: String, on_input: fn(String) -> msg) -> Element(msg) {
  element("md-outlined-text-field", [attribute.value(value), attribute.attribute("label", label), event.on_input(on_input)], [])
}
