import components/checkbox_field
import components/form_field
import components/link_button
import lustre
import lustre/element.{type Element}
import lustre/element/html

pub fn main() {
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

type Model {
  Model(name: String, email: String, newsletter: Bool, terms: Bool)
}

fn init(_flags) -> Model {
  Model(name: "", email: "", newsletter: True, terms: False)
}

type Msg {
  UserUpdatedName(String)
  UserUpdatedEmail(String)
  UserToggledNewsletter
  UserToggledTerms
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    UserUpdatedName(name) -> Model(..model, name: name)
    UserUpdatedEmail(email) -> Model(..model, email: email)
    UserToggledNewsletter -> Model(..model, newsletter: !model.newsletter)
    UserToggledTerms -> Model(..model, terms: !model.terms)
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([], [
    html.h1([], [html.text("Attributes Example")]),
    // Static and Dynamic Attributes
    html.div([attribute.class("section")], [
      html.h2([], [html.text("Form Fields (Static + Dynamic Attributes)")]),
      form_field.render("Name", model.name, "Enter your name"),
      form_field.render("Email", model.email, "Enter your email"),
    ]),
    // Boolean Attributes
    html.div([attribute.class("section")], [
      html.h2([], [html.text("Checkboxes (Boolean Attributes)")]),
      checkbox_field.render("Subscribe to newsletter", model.newsletter),
      checkbox_field.render("Accept terms and conditions", model.terms),
    ]),
    // Dynamic Attributes with Conditionals
    html.div([attribute.class("section")], [
      html.h2([], [html.text("Links (Conditional Attributes)")]),
      link_button.render("/about", "Internal Link", False),
      link_button.render("https://gleam.run", "Gleam Website", True),
      link_button.render("https://lustre.build", "Lustre Docs", True),
    ]),
  ])
}

import lustre/attribute
