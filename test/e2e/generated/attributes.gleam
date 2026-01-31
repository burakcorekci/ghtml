// @generated from all_attrs.lustre
// @hash 976cc101779d78c7cb1ed75f6d637c53914039a81ad85b8fb82ab97bf71eed02
// DO NOT EDIT - regenerate with: gleam run -m lustre_template_gen

import lustre/attribute
import lustre/element.{type Element, text}
import lustre/element/html
import lustre/event

pub fn render(
  value: String,
  is_disabled: Bool,
  on_change: fn(String) -> msg,
  on_click: fn() -> msg,
) -> Element(msg) {
  html.form([attribute.class("form")], [
    html.input([
      attribute.type_("text"),
      attribute.class("input"),
      attribute.value(value),
      attribute.disabled(is_disabled),
      event.on_input(on_change),
    ]),
    html.button([attribute.type_("submit"), event.on_click(on_click())], [
      text("\n Submit\n "),
    ]),
  ])
}
