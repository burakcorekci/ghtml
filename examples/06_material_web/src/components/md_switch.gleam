// @generated from md_switch.lustre
// @hash 3906f35c09861cc84132428eccc3d8a63b2f241588472ed3a938acd3776578af
// DO NOT EDIT - regenerate with: gleam run -m ghtml

import lustre/element.{type Element, element}
import lustre/attribute
import lustre/event

pub fn render(is_on: Bool, on_change: fn() -> msg) -> Element(msg) {
  case is_on { True -> element("md-switch", [attribute.attribute("selected", ""), event.on_click(on_change())], []) False -> element("md-switch", [event.on_click(on_change())], []) }
}
