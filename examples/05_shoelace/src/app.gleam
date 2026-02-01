import components/sl_button
import components/sl_card
import components/sl_checkbox
import components/sl_dialog
import components/sl_input
import components/sl_select
import gleam/dynamic/decode
import lustre
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import types.{Option}

pub fn main() {
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

type Model {
  Model(
    input_value: String,
    checkbox_checked: Bool,
    dialog_open: Bool,
    selected_color: String,
  )
}

fn init(_flags) -> Model {
  Model(
    input_value: "",
    checkbox_checked: False,
    dialog_open: False,
    selected_color: "blue",
  )
}

type Msg {
  UpdateInput(String)
  ToggleCheckbox
  OpenDialog
  CloseDialog
  SelectColor(String)
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    UpdateInput(value) -> Model(..model, input_value: value)
    ToggleCheckbox -> Model(..model, checkbox_checked: !model.checkbox_checked)
    OpenDialog -> Model(..model, dialog_open: True)
    CloseDialog -> Model(..model, dialog_open: False)
    SelectColor(color) -> Model(..model, selected_color: color)
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([], [
    html.h1([], [html.text("Shoelace Components Example")]),
    // Button variants
    html.div([attribute.class("section")], [
      html.h2([], [html.text("Buttons")]),
      html.p([], [
        html.text(
          "Shoelace buttons with different variants. Notice how custom elements use element() instead of html.button().",
        ),
      ]),
      html.div([attribute.class("button-row")], [
        sl_button.render("Default", "default", fn() { OpenDialog }),
        sl_button.render("Primary", "primary", fn() { OpenDialog }),
        sl_button.render("Success", "success", fn() { OpenDialog }),
        sl_button.render("Warning", "warning", fn() { OpenDialog }),
        sl_button.render("Danger", "danger", fn() { OpenDialog }),
      ]),
    ]),
    // Input
    html.div([attribute.class("section")], [
      html.h2([], [html.text("Input")]),
      html.p([], [
        html.text(
          "Shoelace input with @sl-input event. Custom events use event.on(\"sl-input\", decoder).",
        ),
      ]),
      html.div([attribute.class("input-section")], [
        sl_input.render(
          model.input_value,
          "Your Name",
          "Enter your name...",
          // Decoder for sl-input: extract value from event.target.value
          decode_input_value(UpdateInput),
        ),
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
          "Shoelace checkbox with @sl-change event and boolean 'checked' attribute.",
        ),
      ]),
      html.div([attribute.class("checkbox-row")], [
        sl_checkbox.render(
          "Enable notifications",
          model.checkbox_checked,
          // Decoder for sl-change: always return ToggleCheckbox
          decode.success(ToggleCheckbox),
        ),
        html.span([attribute.class("status")], [
          html.text(case model.checkbox_checked {
            True -> "Notifications enabled"
            False -> "Notifications disabled"
          }),
        ]),
      ]),
    ]),
    // Select
    html.div([attribute.class("section")], [
      html.h2([], [html.text("Select")]),
      html.p([], [
        html.text(
          "Shoelace select dropdown with {#each} to render options dynamically.",
        ),
      ]),
      html.div([attribute.class("select-section")], [
        sl_select.render(
          "Favorite Color",
          [
            Option("red", "Red"),
            Option("green", "Green"),
            Option("blue", "Blue"),
            Option("purple", "Purple"),
          ],
          model.selected_color,
          // Decoder for sl-change: extract value from event.target.value
          decode_input_value(SelectColor),
        ),
        html.div([attribute.class("value-display")], [
          html.text("Selected: " <> model.selected_color),
        ]),
      ]),
    ]),
    // Card
    html.div([attribute.class("section")], [
      html.h2([], [html.text("Card")]),
      html.p([], [
        html.text(
          "Shoelace card with slot=\"image\" for image placement. Slots are just regular attributes.",
        ),
      ]),
      sl_card.render(
        "Lustre + Shoelace",
        "Web components integrate seamlessly with Lustre templates. Custom elements are automatically detected and rendered correctly.",
        "https://images.unsplash.com/photo-1559583985-c80d8ad9b29f?w=300&h=200&fit=crop",
      ),
    ]),
    // Dialog
    html.div([attribute.class("section")], [
      html.h2([], [html.text("Dialog")]),
      html.p([], [
        html.text(
          "Click any button above to open the dialog. Uses @sl-hide event to detect when closed.",
        ),
      ]),
      sl_dialog.render(
        "Example Dialog",
        model.dialog_open,
        // Decoder for sl-hide custom event
        decode.success(CloseDialog),
        // Handler for button click
        fn() { CloseDialog },
      ),
    ]),
  ])
}

/// Decoder for extracting input value from Shoelace events
/// Shoelace events store the value at event.target.value
fn decode_input_value(to_msg: fn(String) -> msg) -> decode.Decoder(msg) {
  decode.at(["target", "value"], decode.string)
  |> decode.map(to_msg)
}
