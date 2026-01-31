// @generated from web_components.lustre
// @hash b87a0ef87b2a08f78392a850865b4d2f071cd54c0c2e5e9e799027ff71be3c85
// DO NOT EDIT - regenerate with: gleam run -m lustre_template_gen

import lustre/attribute
import lustre/element.{type Element, element, none, text}

pub fn render(content: String, is_active: Bool) -> Element(msg) {
  element("my-component", [attribute.class("custom")], [
    element("slot-content", [], [text(content)]),
    case is_active {
      True ->
        element("status-indicator", [attribute.attribute("active", "")], [])
      False -> none()
    },
  ])
}
