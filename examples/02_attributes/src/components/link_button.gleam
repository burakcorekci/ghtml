// @generated from link_button.lustre
// @hash 831534114a4c7bd3e02e3516a514258bb05b85b7a7d599ce9e56e7f227649171
// DO NOT EDIT - regenerate with: gleam run -m ghtml

import lustre/element.{type Element, text}
import lustre/element/html
import lustre/attribute

pub fn render(url: String, label: String, is_external: Bool) -> Element(msg) {
  html.a([attribute.href(url), attribute.class("btn"), attribute.target(case is_external { True -> "_blank" False -> "_self" }), attribute.rel(case is_external { True -> "noopener noreferrer" False -> "" })], [text(label)])
}
