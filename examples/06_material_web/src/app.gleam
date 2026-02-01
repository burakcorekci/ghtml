import components/md_button
import components/md_checkbox
import components/md_fab
import components/md_list
import components/md_outlined_button
import components/md_switch
import components/md_text_button
import components/md_textfield
import gleam/int
import lustre
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import types.{ListItem}

pub fn main() {
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

type Model {
  Model(
    input_value: String,
    checkbox_checked: Bool,
    switch_on: Bool,
    fab_clicks: Int,
  )
}

fn init(_flags) -> Model {
  Model(
    input_value: "",
    checkbox_checked: False,
    switch_on: False,
    fab_clicks: 0,
  )
}

type Msg {
  UpdateInput(String)
  ToggleCheckbox
  ToggleSwitch
  IncrementFab
  ButtonClicked
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    UpdateInput(value) -> Model(..model, input_value: value)
    ToggleCheckbox -> Model(..model, checkbox_checked: !model.checkbox_checked)
    ToggleSwitch -> Model(..model, switch_on: !model.switch_on)
    IncrementFab -> Model(..model, fab_clicks: model.fab_clicks + 1)
    ButtonClicked -> model
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([], [
    html.h1([], [html.text("Material Web Components Example")]),
    // Button variants
    html.div([attribute.class("section")], [
      html.h2([], [html.text("Buttons")]),
      html.p([], [
        html.text(
          "Material Web provides three button variants: filled, outlined, and text.",
        ),
      ]),
      html.div([attribute.class("button-row")], [
        md_button.render("Filled", fn() { ButtonClicked }),
        md_outlined_button.render("Outlined", fn() { ButtonClicked }),
        md_text_button.render("Text", fn() { ButtonClicked }),
      ]),
    ]),
    // Text field
    html.div([attribute.class("section")], [
      html.h2([], [html.text("Text Field")]),
      html.p([], [
        html.text(
          "Material Web text field with standard @input event. Uses fn(String) -> msg handler.",
        ),
      ]),
      html.div([attribute.class("input-section")], [
        md_textfield.render(model.input_value, "Your Name", UpdateInput),
        html.div([attribute.class("value-display")], [
          html.text("Current value: " <> model.input_value),
        ]),
      ]),
    ]),
    // Checkbox
    html.div([attribute.class("section")], [
      html.h2([], [html.text("Checkbox")]),
      html.p([], [
        html.text(
          "Material Web checkbox with @click event and boolean 'checked' attribute.",
        ),
      ]),
      html.div([attribute.class("toggle-row")], [
        md_checkbox.render(model.checkbox_checked, fn() { ToggleCheckbox }),
        html.span([attribute.class("status")], [
          html.text(case model.checkbox_checked {
            True -> "Checked"
            False -> "Unchecked"
          }),
        ]),
      ]),
    ]),
    // Switch
    html.div([attribute.class("section")], [
      html.h2([], [html.text("Switch")]),
      html.p([], [
        html.text(
          "Material Web switch with @click event and boolean 'selected' attribute.",
        ),
      ]),
      html.div([attribute.class("toggle-row")], [
        md_switch.render(model.switch_on, fn() { ToggleSwitch }),
        html.span([attribute.class("status")], [
          html.text(case model.switch_on {
            True -> "On"
            False -> "Off"
          }),
        ]),
      ]),
    ]),
    // List
    html.div([attribute.class("section")], [
      html.h2([], [html.text("List")]),
      html.p([], [
        html.text(
          "Material Web list using {#each} to render items with slots for headline and supporting text.",
        ),
      ]),
      html.div([attribute.class("list-section")], [
        md_list.render([
          ListItem("1", "First Item", "Supporting text for the first item"),
          ListItem("2", "Second Item", "Supporting text for the second item"),
          ListItem("3", "Third Item", "Supporting text for the third item"),
        ]),
      ]),
    ]),
    // FAB
    html.div([attribute.class("section")], [
      html.h2([], [html.text("Floating Action Button")]),
      html.p([], [
        html.text(
          "FAB with icon slot. Click the FAB in the bottom-right corner. Clicks: ",
        ),
        html.text(int.to_string(model.fab_clicks)),
      ]),
    ]),
    // FAB positioned fixed
    html.div([attribute.class("fab-container")], [
      md_fab.render("add", fn() { IncrementFab }),
    ]),
  ])
}
