// @generated from checkbox_field.lustre
// @hash 3e97df5262670e6c28d0db6ea000474e3e0cb3d2930d6421c1e6ea8573c3e0e0
// DO NOT EDIT - regenerate with: gleam run -m lustre_template_gen

import lustre/element.{type Element, text}
import lustre/element/html
import lustre/attribute

pub fn render(label: String, is_checked: Bool) -> Element(msg) {
  html.label([attribute.class("checkbox")], [html.input([attribute.type_("checkbox"), attribute.checked(is_checked)]), html.span([], [text(label)])])
}
