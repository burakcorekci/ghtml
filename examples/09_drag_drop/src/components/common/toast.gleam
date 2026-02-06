// @generated from toast.ghtml
// @hash a3430aa0da501a1ca2851b35f74553eabb5ef81f3fb332fb87df2691ec0caa6c
// DO NOT EDIT - regenerate with: gleam run -m ghtml

import lustre/element.{type Element, text, none}
import lustre/element/html
import lustre/attribute
import lustre/event
import model.{type ToastType, Success, Error, Warning, Info}

pub fn render(message: String, toast_type: ToastType, is_visible: Bool, on_dismiss: fn() -> msg) -> Element(msg) {
  case is_visible { True -> html.div([attribute.class("fixed bottom-4 right-4 z-50 animate-slide-up")], [case toast_type { Success -> html.div([attribute.class("bg-green-100 text-green-800 rounded-lg px-4 py-3 flex items-center gap-3 shadow-lg")], [html.span([], [text("Success")]), html.span([], [text(message)]), html.button([attribute.class("ml-4 text-green-600 hover:text-green-800"), event.on_click(on_dismiss())], [text("x")])]) Error -> html.div([attribute.class("bg-red-100 text-red-800 rounded-lg px-4 py-3 flex items-center gap-3 shadow-lg")], [html.span([], [text("Error")]), html.span([], [text(message)]), html.button([attribute.class("ml-4 text-red-600 hover:text-red-800"), event.on_click(on_dismiss())], [text("x")])]) Warning -> html.div([attribute.class("bg-yellow-100 text-yellow-800 rounded-lg px-4 py-3 flex items-center gap-3 shadow-lg")], [html.span([], [text("Warning")]), html.span([], [text(message)]), html.button([attribute.class("ml-4 text-yellow-600 hover:text-yellow-800"), event.on_click(on_dismiss())], [text("x")])]) Info -> html.div([attribute.class("bg-blue-100 text-blue-800 rounded-lg px-4 py-3 flex items-center gap-3 shadow-lg")], [html.span([], [text("Info")]), html.span([], [text(message)]), html.button([attribute.class("ml-4 text-blue-600 hover:text-blue-800"), event.on_click(on_dismiss())], [text("x")])]) }]) False -> none() }
}
