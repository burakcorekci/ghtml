// @generated from md_text_button.lustre
// @hash 83479df0e7a238c6d1038eb4bd5ad4fc65a631d087ab1faa2a6753635f09fbd0
// DO NOT EDIT - regenerate with: gleam run -m ghtml

import lustre/element.{type Element, text, element}
import lustre/event

pub fn render(label: String, on_click: fn() -> msg) -> Element(msg) {
  element("md-text-button", [event.on_click(on_click())], [text(label)])
}
