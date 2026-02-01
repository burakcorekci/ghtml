// @generated from md_button.lustre
// @hash 027af63e8a63ba9a6f8d24a2cced01dd05afbc0021c0b964d5880535388e0d03
// DO NOT EDIT - regenerate with: gleam run -m lustre_template_gen

import lustre/element.{type Element, text, element}
import lustre/event

pub fn render(label: String, on_click: fn() -> msg) -> Element(msg) {
  element("md-filled-button", [event.on_click(on_click())], [text(label)])
}
