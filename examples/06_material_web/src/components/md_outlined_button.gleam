// @generated from md_outlined_button.lustre
// @hash 14ca5a8f35eb1990faa45e8f03e203dbdd9c287861b4bf15bb6b9cb1d6ab5ac8
// DO NOT EDIT - regenerate with: gleam run -m ghtml

import lustre/element.{type Element, text, element}
import lustre/event

pub fn render(label: String, on_click: fn() -> msg) -> Element(msg) {
  element("md-outlined-button", [event.on_click(on_click())], [text(label)])
}
