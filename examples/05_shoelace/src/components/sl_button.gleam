// @generated from sl_button.lustre
// @hash 6a14699afce8c90438d2aa016b57f2d1040bb59228fb6bced67083681dcf5e00
// DO NOT EDIT - regenerate with: gleam run -m ghtml

import lustre/element.{type Element, text, element}
import lustre/attribute
import lustre/event

pub fn render(label: String, variant: String, on_click: fn() -> msg) -> Element(msg) {
  element("sl-button", [attribute.attribute("variant", variant), event.on_click(on_click())], [text(label)])
}
