// @generated from form_field.lustre
// @hash 257060824c9394fbf64e78b80b46d6d9fffd54ec7700784b426ef0491d591779
// DO NOT EDIT - regenerate with: gleam run -m ghtml

import lustre/element.{type Element, text}
import lustre/element/html
import lustre/attribute

pub fn render(label: String, value: String, hint: String) -> Element(msg) {
  html.div([attribute.class("field")], [html.label([attribute.class("label")], [text(label)]), html.input([attribute.type_("text"), attribute.class("input"), attribute.value(value), attribute.placeholder(hint), attribute.required(True)])])
}
