// @generated from md_checkbox.lustre
// @hash 1b69b58744855c81198d4e10be6b68d51eec2d68e0b258f58f24742630f5a6fa
// DO NOT EDIT - regenerate with: gleam run -m ghtml

import lustre/element.{type Element, element}
import lustre/attribute
import lustre/event

pub fn render(is_checked: Bool, on_change: fn() -> msg) -> Element(msg) {
  case is_checked { True -> element("md-checkbox", [attribute.attribute("checked", ""), event.on_click(on_change())], []) False -> element("md-checkbox", [event.on_click(on_change())], []) }
}
