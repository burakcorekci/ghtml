// @generated from todo_item.lustre
// @hash dbef3cd10667b9f5c4007daa8fa5858ad16868dfa40415c4d01245fb6e41281c
// DO NOT EDIT - regenerate with: gleam run -m ghtml

import lustre/element.{type Element, text}
import lustre/element/html
import lustre/attribute
import lustre/event
import types.{type Todo, High, Medium, Low}

pub fn render(t: Todo, on_toggle: fn() -> msg, on_delete: fn() -> msg) -> Element(msg) {
  html.div([attribute.class("todo-item")], [html.input([attribute.type_("checkbox"), attribute.checked(t.completed), event.on_click(on_toggle())]), html.span([attribute.class("text")], [case t.completed { True -> html.s([], [text(t.text)]) False -> text(t.text) }]), case t.priority { High -> html.span([attribute.class("priority high")], [text("!")]) Medium -> html.span([attribute.class("priority medium")], [text("-")]) Low -> html.span([attribute.class("priority low")], [text(".")]) }, html.button([attribute.class("delete"), event.on_click(on_delete())], [text("x")])])
}
