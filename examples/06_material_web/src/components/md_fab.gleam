// @generated from md_fab.lustre
// @hash 3812fe086ebfd76ce4753daee19cc0689da78faadf5bcd4828228eebec57683d
// DO NOT EDIT - regenerate with: gleam run -m lustre_template_gen

import lustre/element.{type Element, text, element}
import lustre/attribute
import lustre/event

pub fn render(icon: String, on_click: fn() -> msg) -> Element(msg) {
  element("md-fab", [event.on_click(on_click())], [element("md-icon", [attribute.attribute("slot", "icon")], [text(icon)])])
}
