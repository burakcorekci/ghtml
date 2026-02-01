// @generated from sl_select.lustre
// @hash ad87be08572d6a008643339b5b729a0df06c7e8c819ffc753c97cd960e8dac65
// DO NOT EDIT - regenerate with: gleam run -m lustre_template_gen

import lustre/element.{type Element, text, element}
import lustre/element/keyed
import lustre/attribute
import lustre/event
import gleam/list
import gleam/int
import types.{type Option}
import gleam/dynamic/decode

pub fn render(label: String, options: List(Option), selected: String, on_change: decode.Decoder(msg)) -> Element(msg) {
  element("sl-select", [attribute.attribute("label", label), attribute.value(selected), event.on("sl-change", on_change)], [keyed.fragment(list.index_map(options, fn(opt, idx) { #(int.to_string(idx), element("sl-option", [attribute.value(opt.value)], [text(opt.label)])) }))])
}
