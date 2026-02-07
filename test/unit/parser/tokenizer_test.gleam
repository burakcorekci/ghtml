import ghtml/parser
import ghtml/types.{
  BooleanAttribute, CaseEnd, CasePattern, CaseStart, DynamicAttribute, EachStart,
  Else, EventAttribute, Expr, HtmlClose, HtmlOpen, IfEnd, IfStart, Import,
  Params, StaticAttribute, Text,
}
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should

// === Import Directive Tests ===

pub fn tokenize_import_test() {
  let input = "@import(gleam/io)"
  let assert Ok(tokens) = parser.tokenize(input)

  should.equal(list.length(tokens), 1)
  case list.first(tokens) {
    Ok(Import(content, _)) -> should.equal(content, "gleam/io")
    _ -> should.fail()
  }
}

pub fn tokenize_import_with_types_test() {
  let input = "@import(gleam/option.{type Option, Some, None})"
  let assert Ok(tokens) = parser.tokenize(input)

  case list.first(tokens) {
    Ok(Import(content, _)) ->
      should.equal(content, "gleam/option.{type Option, Some, None}")
    _ -> should.fail()
  }
}

pub fn tokenize_multiple_imports_test() {
  let input =
    "@import(gleam/io)
@import(gleam/list)"
  let assert Ok(tokens) = parser.tokenize(input)

  should.equal(list.length(tokens), 2)
}

// === Params Directive Tests ===

pub fn tokenize_params_single_test() {
  let input = "@params(name: String)"
  let assert Ok(tokens) = parser.tokenize(input)

  case list.first(tokens) {
    Ok(Params(params, _)) -> {
      should.equal(list.length(params), 1)
      should.equal(list.first(params), Ok(#("name", "String")))
    }
    _ -> should.fail()
  }
}

pub fn tokenize_params_multiple_test() {
  let input =
    "@params(
  name: String,
  count: Int,
  active: Bool,
)"
  let assert Ok(tokens) = parser.tokenize(input)

  case list.first(tokens) {
    Ok(Params(params, _)) -> {
      should.equal(list.length(params), 3)
    }
    _ -> should.fail()
  }
}

pub fn tokenize_params_complex_types_test() {
  let input = "@params(items: List(Item), handler: fn(String) -> msg)"
  let assert Ok(tokens) = parser.tokenize(input)

  case list.first(tokens) {
    Ok(Params(params, _)) -> {
      should.equal(list.length(params), 2)
      // Check that complex types are parsed correctly
      let assert Ok(#(_, type_str)) = list.last(params)
      should.equal(type_str, "fn(String) -> msg")
    }
    _ -> should.fail()
  }
}

// === HTML Tag Tests ===

pub fn tokenize_html_open_tag_test() {
  let input = "<div>"
  let assert Ok(tokens) = parser.tokenize(input)

  case list.first(tokens) {
    Ok(HtmlOpen(tag, attrs, self_closing, _)) -> {
      should.equal(tag, "div")
      should.equal(attrs, [])
      should.be_false(self_closing)
    }
    _ -> should.fail()
  }
}

pub fn tokenize_html_close_tag_test() {
  let input = "</div>"
  let assert Ok(tokens) = parser.tokenize(input)

  case list.first(tokens) {
    Ok(HtmlClose(tag, _)) -> should.equal(tag, "div")
    _ -> should.fail()
  }
}

pub fn tokenize_self_closing_tag_test() {
  let input = "<br />"
  let assert Ok(tokens) = parser.tokenize(input)

  case list.first(tokens) {
    Ok(HtmlOpen(tag, _, self_closing, _)) -> {
      should.equal(tag, "br")
      should.be_true(self_closing)
    }
    _ -> should.fail()
  }
}

pub fn tokenize_custom_element_test() {
  let input = "<sl-button></sl-button>"
  let assert Ok(tokens) = parser.tokenize(input)

  should.equal(list.length(tokens), 2)
  case list.first(tokens) {
    Ok(HtmlOpen(tag, _, _, _)) -> should.equal(tag, "sl-button")
    _ -> should.fail()
  }
}

// === Attribute Tests ===

pub fn tokenize_static_attr_test() {
  let input = "<div class=\"container\">"
  let assert Ok(tokens) = parser.tokenize(input)

  case list.first(tokens) {
    Ok(HtmlOpen(_, attrs, _, _)) -> {
      should.equal(list.length(attrs), 1)
      case list.first(attrs) {
        Ok(StaticAttribute(name, value)) -> {
          should.equal(name, "class")
          should.equal(value, "container")
        }
        _ -> should.fail()
      }
    }
    _ -> should.fail()
  }
}

pub fn tokenize_dynamic_attr_test() {
  let input = "<div class={my_class}>"
  let assert Ok(tokens) = parser.tokenize(input)

  case list.first(tokens) {
    Ok(HtmlOpen(_, attrs, _, _)) -> {
      case list.first(attrs) {
        Ok(DynamicAttribute(name, expr)) -> {
          should.equal(name, "class")
          should.equal(expr, "my_class")
        }
        _ -> should.fail()
      }
    }
    _ -> should.fail()
  }
}

pub fn tokenize_event_attr_test() {
  let input = "<button @click={handle_click()}>"
  let assert Ok(tokens) = parser.tokenize(input)

  case list.first(tokens) {
    Ok(HtmlOpen(_, attrs, _, _)) -> {
      case list.first(attrs) {
        Ok(EventAttribute(event, handler, modifiers)) -> {
          should.equal(event, "click")
          should.equal(handler, "handle_click()")
          should.equal(modifiers, [])
        }
        _ -> should.fail()
      }
    }
    _ -> should.fail()
  }
}

pub fn tokenize_event_attr_prevent_test() {
  let input = "<button @click.prevent={handle_click()}>"
  let assert Ok(tokens) = parser.tokenize(input)

  case list.first(tokens) {
    Ok(HtmlOpen(_, attrs, _, _)) -> {
      case list.first(attrs) {
        Ok(EventAttribute(event, handler, modifiers)) -> {
          should.equal(event, "click")
          should.equal(handler, "handle_click()")
          should.equal(modifiers, ["prevent"])
        }
        _ -> should.fail()
      }
    }
    _ -> should.fail()
  }
}

pub fn tokenize_event_attr_stop_test() {
  let input = "<div @click.stop={handle_click()}>"
  let assert Ok(tokens) = parser.tokenize(input)

  case list.first(tokens) {
    Ok(HtmlOpen(_, attrs, _, _)) -> {
      case list.first(attrs) {
        Ok(EventAttribute(event, handler, modifiers)) -> {
          should.equal(event, "click")
          should.equal(handler, "handle_click()")
          should.equal(modifiers, ["stop"])
        }
        _ -> should.fail()
      }
    }
    _ -> should.fail()
  }
}

pub fn tokenize_event_attr_prevent_stop_test() {
  let input = "<div @on:drop.prevent.stop={on_drop(Todo)}>"
  let assert Ok(tokens) = parser.tokenize(input)

  case list.first(tokens) {
    Ok(HtmlOpen(_, attrs, _, _)) -> {
      case list.first(attrs) {
        Ok(EventAttribute(event, handler, modifiers)) -> {
          should.equal(event, "on:drop")
          should.equal(handler, "on_drop(Todo)")
          should.equal(modifiers, ["prevent", "stop"])
        }
        _ -> should.fail()
      }
    }
    _ -> should.fail()
  }
}

pub fn tokenize_event_attr_stop_prevent_order_test() {
  let input = "<div @click.stop.prevent={handler}>"
  let assert Ok(tokens) = parser.tokenize(input)

  case list.first(tokens) {
    Ok(HtmlOpen(_, attrs, _, _)) -> {
      case list.first(attrs) {
        Ok(EventAttribute(event, handler, modifiers)) -> {
          should.equal(event, "click")
          should.equal(handler, "handler")
          should.equal(modifiers, ["stop", "prevent"])
        }
        _ -> should.fail()
      }
    }
    _ -> should.fail()
  }
}

pub fn tokenize_event_attr_unknown_modifier_error_test() {
  let input = "<div @click.unknown={handler}>"
  let result = parser.tokenize(input)

  case result {
    Error(errors) -> should.be_true(errors != [])
    Ok(_) -> should.fail()
  }
}

pub fn tokenize_boolean_attr_test() {
  let input = "<input disabled>"
  let assert Ok(tokens) = parser.tokenize(input)

  case list.first(tokens) {
    Ok(HtmlOpen(_, attrs, _, _)) -> {
      case list.first(attrs) {
        Ok(BooleanAttribute(name)) -> should.equal(name, "disabled")
        _ -> should.fail()
      }
    }
    _ -> should.fail()
  }
}

pub fn tokenize_multiple_attrs_test() {
  let input = "<input type=\"text\" class={cls} disabled @input={on_input}>"
  let assert Ok(tokens) = parser.tokenize(input)

  case list.first(tokens) {
    Ok(HtmlOpen(_, attrs, _, _)) -> {
      should.equal(list.length(attrs), 4)
    }
    _ -> should.fail()
  }
}

// === Text Content Tests ===

pub fn tokenize_text_test() {
  let input = "Hello, World!"
  let assert Ok(tokens) = parser.tokenize(input)

  case list.first(tokens) {
    Ok(Text(content, _)) -> should.equal(content, "Hello, World!")
    _ -> should.fail()
  }
}

pub fn tokenize_escaped_braces_test() {
  let input = "Use {{braces}} like this"
  let assert Ok(tokens) = parser.tokenize(input)

  case list.first(tokens) {
    Ok(Text(content, _)) -> should.equal(content, "Use {braces} like this")
    _ -> should.fail()
  }
}

// === Expression Tests ===

pub fn tokenize_expression_test() {
  let input = "{user.name}"
  let assert Ok(tokens) = parser.tokenize(input)

  case list.first(tokens) {
    Ok(Expr(content, _)) -> should.equal(content, "user.name")
    _ -> should.fail()
  }
}

pub fn tokenize_expression_with_function_call_test() {
  let input = "{int.to_string(count)}"
  let assert Ok(tokens) = parser.tokenize(input)

  case list.first(tokens) {
    Ok(Expr(content, _)) -> should.equal(content, "int.to_string(count)")
    _ -> should.fail()
  }
}

pub fn tokenize_expression_with_nested_braces_test() {
  let input = "{some_fn(#(a, b))}"
  let assert Ok(tokens) = parser.tokenize(input)

  case list.first(tokens) {
    Ok(Expr(content, _)) -> should.equal(content, "some_fn(#(a, b))")
    _ -> should.fail()
  }
}

// === Control Flow Tests ===

pub fn tokenize_if_else_test() {
  let input = "{#if show}visible{:else}hidden{/if}"
  let assert Ok(tokens) = parser.tokenize(input)

  should.equal(list.length(tokens), 5)

  case tokens {
    [IfStart(cond, _), Text(t1, _), Else(_), Text(t2, _), IfEnd(_)] -> {
      should.equal(cond, "show")
      should.equal(t1, "visible")
      should.equal(t2, "hidden")
    }
    _ -> should.fail()
  }
}

pub fn tokenize_if_without_else_test() {
  let input = "{#if show}visible{/if}"
  let assert Ok(tokens) = parser.tokenize(input)

  should.equal(list.length(tokens), 3)
  case list.first(tokens) {
    Ok(IfStart(cond, _)) -> should.equal(cond, "show")
    _ -> should.fail()
  }
}

pub fn tokenize_each_test() {
  let input = "{#each items as item}content{/each}"
  let assert Ok(tokens) = parser.tokenize(input)

  case list.first(tokens) {
    Ok(EachStart(collection, item, index, _)) -> {
      should.equal(collection, "items")
      should.equal(item, "item")
      should.equal(index, None)
    }
    _ -> should.fail()
  }
}

pub fn tokenize_each_with_index_test() {
  let input = "{#each items as item, i}content{/each}"
  let assert Ok(tokens) = parser.tokenize(input)

  case list.first(tokens) {
    Ok(EachStart(collection, item, index, _)) -> {
      should.equal(collection, "items")
      should.equal(item, "item")
      should.equal(index, Some("i"))
    }
    _ -> should.fail()
  }
}

pub fn tokenize_case_test() {
  let input = "{#case result}{:Ok(x)}success{:Error(e)}error{/case}"
  let assert Ok(tokens) = parser.tokenize(input)

  case tokens {
    [
      CaseStart(expr, _),
      CasePattern(p1, _),
      Text(_, _),
      CasePattern(p2, _),
      Text(_, _),
      CaseEnd(_),
    ] -> {
      should.equal(expr, "result")
      should.equal(p1, "Ok(x)")
      should.equal(p2, "Error(e)")
    }
    _ -> should.fail()
  }
}

// === HTML Comment Tests ===

pub fn tokenize_strips_html_comments_test() {
  let input = "<div><!-- comment --></div>"
  let assert Ok(tokens) = parser.tokenize(input)

  // Comment should be stripped, leaving only open and close tags
  should.equal(list.length(tokens), 2)
}

// === Complex Template Tests ===

pub fn tokenize_full_template_test() {
  let input =
    "@import(gleam/io)

@params(name: String)

<div class=\"greeting\">
  Hello, {name}!
</div>"

  let assert Ok(tokens) = parser.tokenize(input)

  // Should have: Import, Params, HtmlOpen, Text, Expr, Text, HtmlClose
  should.be_true(list.length(tokens) >= 5)
}

// === Error Handling Tests ===

pub fn tokenize_unclosed_expression_error_test() {
  let input = "{unclosed"
  let result = parser.tokenize(input)

  case result {
    Error(errors) -> should.be_true(errors != [])
    Ok(_) -> should.fail()
  }
}

pub fn tokenize_unclosed_tag_error_test() {
  let input = "<div class=\"test"
  let result = parser.tokenize(input)

  case result {
    Error(errors) -> should.be_true(errors != [])
    Ok(_) -> should.fail()
  }
}

// === Position Tracking Tests ===

pub fn tokenize_position_tracking_test() {
  let input =
    "line1
<div>"
  let assert Ok(tokens) = parser.tokenize(input)

  // The <div> should be on line 2
  case list.last(tokens) {
    Ok(HtmlOpen(_, _, _, span)) -> {
      should.equal(span.start.line, 2)
    }
    _ -> should.fail()
  }
}
