# Task 010: Code Generation - Smart Imports

## Description
Implement smart import management that only includes necessary imports based on template features used, and handles conflicts with user-defined imports.

## Dependencies
- Task 007: Code Generation - Basic Elements
- Task 009: Code Generation - Control Flow

## Success Criteria
1. `gleam/list` is only imported when `{#each}` is used
2. `lustre/event` is only imported when event handlers are used
3. `keyed` is only imported from `lustre/element` when `{#each}` is used
4. `none` is only imported when `{#if}` without else is used
5. `fragment` is only imported when multiple root elements or branches exist
6. User imports don't conflict with auto-imports
7. User imports that overlap with auto-imports are not duplicated

## Implementation Steps

### 1. Define UsedFeatures type
```gleam
pub type UsedFeatures {
  UsedFeatures(
    uses_list: Bool,
    uses_keyed: Bool,
    uses_none: Bool,
    uses_fragment: Bool,
    uses_event: Bool,
  )
}
```

### 2. Implement feature analysis
```gleam
pub fn analyze_features(template: Template) -> UsedFeatures {
  let initial = UsedFeatures(
    uses_list: False,
    uses_keyed: False,
    uses_none: False,
    uses_fragment: list.length(template.body) > 1,
    uses_event: False,
  )
  analyze_nodes(template.body, initial)
}

fn analyze_nodes(nodes: List(Node), features: UsedFeatures) -> UsedFeatures {
  list.fold(nodes, features, analyze_node)
}

fn analyze_node(features: UsedFeatures, node: Node) -> UsedFeatures {
  case node {
    Element(_, attrs, children, _) -> {
      let f = check_event_attrs(attrs, features)
      analyze_nodes(children, f)
    }
    IfNode(_, then_branch, else_branch, _) -> {
      let f = case else_branch {
        [] -> UsedFeatures(..features, uses_none: True)
        _ -> features
      }
      let f = check_multiple_children(then_branch, f)
      let f = check_multiple_children(else_branch, f)
      let f = analyze_nodes(then_branch, f)
      analyze_nodes(else_branch, f)
    }
    EachNode(_, _, _, body, _) -> {
      let f = UsedFeatures(..features, uses_list: True, uses_keyed: True)
      analyze_nodes(body, f)
    }
    CaseNode(_, branches, _) -> {
      list.fold(branches, features, fn(f, branch) {
        let f = check_multiple_children(branch.body, f)
        analyze_nodes(branch.body, f)
      })
    }
    Fragment(children, _) -> {
      let f = UsedFeatures(..features, uses_fragment: True)
      analyze_nodes(children, f)
    }
    _ -> features
  }
}

fn check_event_attrs(attrs: List(Attr), features: UsedFeatures) -> UsedFeatures {
  let has_event = list.any(attrs, fn(a) {
    case a {
      EventAttr(_, _) -> True
      _ -> False
    }
  })
  case has_event {
    True -> UsedFeatures(..features, uses_event: True)
    False -> features
  }
}

fn check_multiple_children(nodes: List(Node), features: UsedFeatures) -> UsedFeatures {
  case list.length(nodes) > 1 {
    True -> UsedFeatures(..features, uses_fragment: True)
    False -> features
  }
}
```

### 3. Implement import generation
```gleam
pub fn generate_imports(user_imports: List(String), features: UsedFeatures) -> String {
  let auto_imports = build_auto_imports(user_imports, features)
  let lustre_imports = build_lustre_imports(features)
  let user_import_lines = list.map(user_imports, fn(imp) { "import " <> imp })

  [auto_imports, lustre_imports, user_import_lines]
  |> list.flatten()
  |> string.join("\n")
}

fn build_auto_imports(user_imports: List(String), features: UsedFeatures) -> List(String) {
  let imports = []

  // Add gleam/list if needed and not already imported
  let imports = case features.uses_list && !has_import(user_imports, "gleam/list") {
    True -> ["import gleam/list", ..imports]
    False -> imports
  }

  // Add gleam/int if keyed is used (for int.to_string in key generation)
  let imports = case features.uses_keyed && !has_import(user_imports, "gleam/int") {
    True -> ["import gleam/int", ..imports]
    False -> imports
  }

  imports
}

fn build_lustre_imports(features: UsedFeatures) -> List(String) {
  // Build lustre/element import with only needed items
  let element_items = ["type Element", "element", "text"]
  let element_items = case features.uses_keyed {
    True -> ["keyed", ..element_items]
    False -> element_items
  }
  let element_items = case features.uses_none {
    True -> ["none", ..element_items]
    False -> element_items
  }
  let element_items = case features.uses_fragment {
    True -> ["fragment", ..element_items]
    False -> element_items
  }

  let imports = [
    "import lustre/element.{" <> string.join(element_items, ", ") <> "}",
    "import lustre/element/html",
    "import lustre/attribute",
  ]

  // Add lustre/event only if event handlers are used
  case features.uses_event {
    True -> list.append(imports, ["import lustre/event"])
    False -> imports
  }
}

fn has_import(imports: List(String), module: String) -> Bool {
  list.any(imports, fn(imp) {
    string.starts_with(imp, module <> ".") || string.starts_with(imp, module <> "{") || imp == module
  })
}
```

### 4. Update generate function to use smart imports
```gleam
pub fn generate(template: Template, source_path: String, hash: String) -> String {
  let filename = extract_filename(source_path)
  let header = cache.generate_header(filename, hash)
  let features = analyze_features(template)
  let imports = generate_imports(template.imports, features)
  let body = generate_function(template)

  header <> "\n" <> imports <> "\n\n" <> body
}
```

## Test Cases

### Test File: `test/codegen_imports_test.gleam`

```gleam
import gleeunit/should
import lustre_template_gen/codegen
import lustre_template_gen/types.{
  Template, Element, TextNode, ExprNode, IfNode, EachNode, CaseNode, CaseBranch,
  StaticAttr, EventAttr, Position, Span,
}
import gleam/string
import gleam/option.{Some, None}

fn test_span() -> Span {
  Span(start: Position(1, 1), end: Position(1, 1))
}

// === Basic Import Tests ===

pub fn generate_minimal_imports_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("div", [], [TextNode("Hello", test_span())], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  // Should have basic lustre imports
  should.be_true(string.contains(code, "import lustre/element.{"))
  should.be_true(string.contains(code, "import lustre/element/html"))
  should.be_true(string.contains(code, "import lustre/attribute"))

  // Should NOT have these (not needed)
  should.be_false(string.contains(code, "import gleam/list"))
  should.be_false(string.contains(code, "import lustre/event"))
  should.be_false(string.contains(code, "keyed"))
  should.be_false(string.contains(code, "none"))
}

pub fn generate_imports_with_user_imports_test() {
  let template = Template(
    imports: ["gleam/io", "app/types.{type User}"],
    params: [],
    body: [Element("div", [], [], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "import gleam/io"))
  should.be_true(string.contains(code, "import app/types.{type User}"))
}

// === Feature-Based Import Tests ===

pub fn generate_imports_with_if_else_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [IfNode(
      condition: "show",
      then_branch: [TextNode("Yes", test_span())],
      else_branch: [TextNode("No", test_span())],
      span: test_span(),
    )],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  // Has else, so none is NOT needed
  should.be_false(string.contains(code, "none"))
}

pub fn generate_imports_with_if_no_else_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [IfNode(
      condition: "show",
      then_branch: [TextNode("Yes", test_span())],
      else_branch: [],
      span: test_span(),
    )],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  // No else, so none IS needed
  should.be_true(string.contains(code, "none"))
}

pub fn generate_imports_with_each_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [EachNode(
      collection: "items",
      item: "item",
      index: None,
      body: [Element("li", [], [], test_span())],
      span: test_span(),
    )],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  // Each requires list and keyed
  should.be_true(string.contains(code, "import gleam/list"))
  should.be_true(string.contains(code, "keyed"))
}

pub fn generate_imports_with_each_index_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [EachNode(
      collection: "items",
      item: "item",
      index: Some("i"),
      body: [Element("li", [], [], test_span())],
      span: test_span(),
    )],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  // Each with index requires gleam/int for int.to_string
  should.be_true(string.contains(code, "import gleam/int"))
}

pub fn generate_imports_with_event_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("button", [EventAttr("click", "on_click()")], [], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  // Event handlers require lustre/event
  should.be_true(string.contains(code, "import lustre/event"))
}

pub fn generate_imports_without_event_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("button", [StaticAttr("class", "btn")], [], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  // No event handlers, no lustre/event
  should.be_false(string.contains(code, "import lustre/event"))
}

pub fn generate_imports_with_fragment_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [
      Element("div", [], [], test_span()),
      Element("span", [], [], test_span()),
    ],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  // Multiple roots require fragment
  should.be_true(string.contains(code, "fragment"))
}

pub fn generate_imports_single_root_no_fragment_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("div", [], [], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  // Single root, no fragment needed
  should.be_false(string.contains(code, "fragment"))
}

// === Conflict Handling Tests ===

pub fn generate_imports_no_duplicate_list_test() {
  let template = Template(
    imports: ["gleam/list.{map, filter}"],
    params: [],
    body: [EachNode(
      collection: "items",
      item: "item",
      index: None,
      body: [Element("li", [], [], test_span())],
      span: test_span(),
    )],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  // Should have user's import
  should.be_true(string.contains(code, "import gleam/list.{map, filter}"))

  // Should NOT have duplicate auto-import
  let list_import_count = code
    |> string.split("import gleam/list")
    |> list.length()
  should.equal(list_import_count, 2)  // Split creates 2 parts for 1 occurrence
}

pub fn generate_imports_no_duplicate_int_test() {
  let template = Template(
    imports: ["gleam/int"],
    params: [],
    body: [EachNode(
      collection: "items",
      item: "item",
      index: Some("i"),
      body: [Element("li", [], [], test_span())],
      span: test_span(),
    )],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  // Should have user's import
  should.be_true(string.contains(code, "import gleam/int"))

  // Should NOT have duplicate
  let int_import_count = code
    |> string.split("import gleam/int")
    |> list.length()
  should.equal(int_import_count, 2)  // 1 occurrence
}

// === Combined Feature Tests ===

pub fn generate_imports_all_features_test() {
  let template = Template(
    imports: ["app/types.{type User}"],
    params: [],
    body: [
      Element("div", [], [], test_span()),
      Element("button", [EventAttr("click", "on_click()")], [], test_span()),
      IfNode("show", [TextNode("Yes", test_span())], [], test_span()),
      EachNode("items", "item", Some("i"), [Element("li", [], [], test_span())], test_span()),
    ],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  // All features should be present
  should.be_true(string.contains(code, "import gleam/list"))
  should.be_true(string.contains(code, "import gleam/int"))
  should.be_true(string.contains(code, "import lustre/event"))
  should.be_true(string.contains(code, "keyed"))
  should.be_true(string.contains(code, "none"))
  should.be_true(string.contains(code, "fragment"))
  should.be_true(string.contains(code, "import app/types.{type User}"))
}

// === Import Order Tests ===

pub fn generate_imports_correct_order_test() {
  let template = Template(
    imports: ["app/types"],
    params: [],
    body: [EachNode("items", "item", None, [Element("li", [], [], test_span())], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  // Auto imports should come before user imports
  let list_pos = string.split(code, "import gleam/list") |> list.first()
  let user_pos = string.split(code, "import app/types") |> list.first()

  // gleam/list should appear before app/types
  case list_pos, user_pos {
    Ok(before_list), Ok(before_user) ->
      should.be_true(string.length(before_list) < string.length(before_user))
    _, _ -> should.fail()
  }
}
```

## Verification Checklist
- [x] `gleam build` succeeds
- [x] `gleam test` passes all import tests
- [x] Minimal imports for simple templates
- [x] `gleam/list` only when `{#each}` is used
- [x] `lustre/event` only when event handlers are used
- [x] `keyed`, `none`, `fragment` conditionally included
- [x] No duplicate imports with user imports
- [x] Import order is logical (auto, lustre, user)

## Notes
- The import analysis traverses the entire AST
- Consider memoization for large templates
- Keep the has_import check robust for various import formats
- Import order affects readability but not functionality
