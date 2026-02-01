// @generated from card.lustre
// @hash 95bb459b7e1444e9bab0eb6bcbe63f78356df7474503e0fee159fbe5ef7fe6fa
// DO NOT EDIT - regenerate with: gleam run -m lustre_template_gen

import lustre/element.{type Element, text}
import lustre/element/html
import lustre/attribute

pub fn render(title: String, body: String, image_url: String) -> Element(msg) {
  html.div([attribute.class("max-w-sm rounded-lg overflow-hidden shadow-lg bg-white")], [html.img([attribute.class("w-full h-48 object-cover"), attribute.src(image_url), attribute.alt("")]), html.div([attribute.class("px-6 py-4")], [html.h3([attribute.class("font-bold text-xl mb-2 text-gray-800")], [text(title)]), html.p([attribute.class("text-gray-600 text-base")], [text(body)])])])
}
