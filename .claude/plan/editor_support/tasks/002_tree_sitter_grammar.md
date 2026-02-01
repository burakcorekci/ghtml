# Task 002: Tree-sitter Grammar

## Description

Implement a complete tree-sitter grammar for `.lustre` template files. This grammar will be the foundation for syntax highlighting in Zed, Neovim, Helix, and other modern editors that support tree-sitter.

## Dependencies

- 001_directory_structure - Directory structure must be set up first

## Success Criteria

1. Grammar parses all `.lustre` files in `test/fixtures/` without errors
2. All syntax elements are correctly identified (directives, tags, expressions, control flow)
3. `tree-sitter test` passes with comprehensive test cases
4. Highlighting queries produce appropriate syntax highlighting
5. Grammar handles edge cases (nested expressions, multiline attributes)

## Implementation Steps

### 1. Define Grammar Rules in grammar.js

The grammar must handle these constructs:

**Directives:**
```
@import(gleam/int)
@import(app/types.{type User, Active, Inactive})
@params(name: String, items: List(String))
```

**HTML Elements:**
```
<div class="container">content</div>
<input type="text" disabled />
```

**Expression Interpolation:**
```
{name}
{int.to_string(count)}
{user.name}
```

**Control Flow:**
```
{#if condition}...{:else}...{/if}
{#each items as item, index}...{/each}
{#case expression}{:Pattern}...{/case}
```

**Event Handlers:**
```
@click={handler()}
@input={on_change}
```

**Dynamic Attributes:**
```
value={variable}
class={dynamic_class}
```

### 2. Grammar Structure

```javascript
module.exports = grammar({
  name: 'lustre',

  extras: $ => [/\s+/],

  rules: {
    source_file: $ => repeat($._node),

    _node: $ => choice(
      $.directive,
      $.element,
      $.self_closing_element,
      $.expression,
      $.if_block,
      $.each_block,
      $.case_block,
      $.text
    ),

    // Directives
    directive: $ => seq(
      '@',
      field('name', $.identifier),
      '(',
      optional(field('content', $.directive_content)),
      ')'
    ),

    // Elements
    element: $ => seq(
      $.start_tag,
      repeat($._node),
      $.end_tag
    ),

    // ... additional rules
  }
});
```

### 3. Create Highlight Queries (queries/highlights.scm)

```scheme
; Directives
(directive "@" @keyword)
(directive name: (identifier) @function)

; Tags
(tag_name) @tag
(attribute_name) @attribute
(attribute_value) @string

; Expressions
(expression "{" @punctuation.bracket)
(expression "}" @punctuation.bracket)
(expression (identifier) @variable)
(expression (function_call name: (identifier) @function))

; Control flow keywords
(if_block "{#if" @keyword.control)
(if_block "{:else}" @keyword.control)
(if_block "{/if}" @keyword.control)

(each_block "{#each" @keyword.control)
(each_block "as" @keyword)
(each_block "{/each}" @keyword.control)

(case_block "{#case" @keyword.control)
(case_block "{/case}" @keyword.control)
(case_pattern) @constructor

; Event handlers
(event_handler "@" @keyword)
(event_handler name: (identifier) @function)

; Types (in params)
(type_annotation type: (type_identifier) @type)

; Strings
(quoted_string) @string

; Comments (if supported)
(comment) @comment
```

### 4. Create Test Cases (test/corpus/*.txt)

Tree-sitter uses a specific test format:

```
================
Basic element
================
<div>Hello</div>
---

(source_file
  (element
    (start_tag (tag_name))
    (text)
    (end_tag (tag_name))))

================
Expression interpolation
================
<p>{name}</p>
---

(source_file
  (element
    (start_tag (tag_name))
    (expression (identifier))
    (end_tag (tag_name))))
```

### 5. Generate and Test

```bash
cd editors/tree-sitter-lustre
npm install
npm run build      # tree-sitter generate
npm run test       # tree-sitter test
npm run parse -- ../../test/fixtures/simple/basic.lustre
```

## Test Cases

Create test corpus files for:
1. Basic elements and text
2. Self-closing elements
3. Attributes (static, dynamic, boolean)
4. Expression interpolation
5. Directives (@import, @params)
6. If blocks (with else)
7. Each blocks (with index)
8. Case blocks (with patterns)
9. Event handlers (@click, @input)
10. Nested structures
11. Multiline constructs

## Verification Checklist

- [ ] `tree-sitter generate` succeeds
- [ ] `tree-sitter test` passes all test cases
- [ ] Parses `test/fixtures/simple/basic.lustre` correctly
- [ ] Parses `test/fixtures/attributes/all_attrs.lustre` correctly
- [ ] Parses `test/fixtures/control_flow/full.lustre` correctly
- [ ] Highlight queries cover all syntax elements
- [ ] No ambiguity warnings from tree-sitter

## Notes

- Start with core HTML-like syntax, then add Lustre-specific constructs
- Tree-sitter grammars use PEG-like syntax with JavaScript DSL
- The `extras` rule handles whitespace automatically
- Use `field()` to name important nodes for queries
- Refer to tree-sitter-html and tree-sitter-svelte for inspiration

## Files to Modify

- `editors/tree-sitter-lustre/grammar.js` - Complete grammar implementation
- `editors/tree-sitter-lustre/queries/highlights.scm` - Syntax highlighting queries
- `editors/tree-sitter-lustre/test/corpus/*.txt` - Test cases (new directory)

## References

- [Tree-sitter Grammar Documentation](https://tree-sitter.github.io/tree-sitter/creating-parsers)
- [tree-sitter-html](https://github.com/tree-sitter/tree-sitter-html)
- [tree-sitter-svelte](https://github.com/Himujjal/tree-sitter-svelte)
