# Task 003: Zed Extension

## Description

Create a Zed editor extension that provides syntax highlighting for `.lustre` files using the tree-sitter grammar. This allows Zed users to have proper language support when editing Lustre templates.

## Dependencies

- 002_tree_sitter_grammar - Tree-sitter grammar must be complete and working

## Success Criteria

1. Zed recognizes `.lustre` files as Lustre language
2. Syntax highlighting works correctly in Zed
3. Extension can be installed locally for testing
4. Extension is structured for publishing to Zed Extensions registry

## Implementation Steps

### 1. Update extension.toml

```toml
id = "lustre"
name = "Lustre Templates"
description = "Syntax highlighting for Lustre template files (.lustre)"
version = "0.1.0"
schema_version = 1
authors = ["Your Name <email@example.com>"]
repository = "https://github.com/user/lustre_template_gen"

[grammars.lustre]
repository = "https://github.com/user/lustre_template_gen"
path = "editors/tree-sitter-lustre"
commit = ""  # Will be filled when publishing
```

### 2. Create Language Configuration

`languages/lustre/config.toml`:

```toml
name = "Lustre"
grammar = "lustre"
path_suffixes = ["lustre"]
line_comments = ["// "]  # If comments are supported
brackets = [
  { start = "{", end = "}", close = true, newline = true },
  { start = "[", end = "]", close = true, newline = true },
  { start = "(", end = ")", close = true, newline = true },
  { start = "<", end = ">", close = false, newline = false },
  { start = "\"", end = "\"", close = true, newline = false },
]
autoclose_before = ";:.,=}])>\" \n\t"
```

### 3. Copy Highlight Queries

Zed uses tree-sitter queries directly. Copy or symlink from tree-sitter-lustre:

`languages/lustre/highlights.scm`:
```scheme
; Copy content from editors/tree-sitter-lustre/queries/highlights.scm
```

### 4. Add Optional Queries

`languages/lustre/injections.scm` (for embedded languages if needed):
```scheme
; Inject Gleam into expression content
((expression) @injection.content
  (#set! injection.language "gleam"))
```

`languages/lustre/brackets.scm`:
```scheme
(element
  (start_tag "<" @open)
  (end_tag ">" @close))

("{" @open "}" @close)
("(" @open ")" @close)
```

`languages/lustre/indents.scm`:
```scheme
(element) @indent
(if_block) @indent
(each_block) @indent
(case_block) @indent

(end_tag) @outdent
"{/if}" @outdent
"{/each}" @outdent
"{/case}" @outdent
```

### 5. Create README

`README.md`:
```markdown
# Lustre Templates for Zed

Syntax highlighting for [Lustre](https://lustre.build/) template files (`.lustre`).

## Features

- Syntax highlighting for Lustre template syntax
- Proper recognition of:
  - Directives (`@import`, `@params`)
  - HTML-like elements and attributes
  - Expression interpolation (`{expression}`)
  - Control flow blocks (`{#if}`, `{#each}`, `{#case}`)
  - Event handlers (`@click`, `@input`)

## Installation

### From Zed Extensions

1. Open Zed
2. Open the extensions panel (Cmd+Shift+X)
3. Search for "Lustre"
4. Click Install

### Local Development

1. Clone the repository
2. In Zed, use `zed: Install Dev Extension`
3. Select the `editors/zed-lustre` directory
```

### 6. Test Locally

```bash
# In Zed, open command palette and run:
# "zed: Install Dev Extension"
# Select: editors/zed-lustre

# Open a .lustre file and verify highlighting
```

## Directory Structure

```
zed-lustre/
├── extension.toml
├── README.md
├── languages/
│   └── lustre/
│       ├── config.toml
│       ├── highlights.scm
│       ├── injections.scm     # Optional
│       ├── brackets.scm       # Optional
│       └── indents.scm        # Optional
└── grammars/
    └── .gitkeep               # Grammar fetched at build time
```

## Test Cases

Manual testing in Zed:

1. Open `test/fixtures/simple/basic.lustre` - verify basic highlighting
2. Open `test/fixtures/control_flow/full.lustre` - verify control flow keywords
3. Open `test/fixtures/attributes/all_attrs.lustre` - verify attribute highlighting
4. Create new `.lustre` file - verify file type detection
5. Test bracket matching with `{`, `(`, `<`

## Verification Checklist

- [ ] Extension installs without errors in Zed
- [ ] `.lustre` files are recognized as Lustre language
- [ ] Directives (`@import`, `@params`) are highlighted
- [ ] HTML tags and attributes are highlighted
- [ ] Expressions `{...}` are highlighted
- [ ] Control flow keywords are highlighted
- [ ] Event handlers (`@click`) are highlighted
- [ ] Bracket matching works
- [ ] README is clear and accurate

## Notes

- Zed fetches grammars from git repositories at build time
- For local dev, use "Install Dev Extension" which uses local grammar
- The `commit` field in extension.toml is required for publishing
- Consider adding `injections.scm` to highlight Gleam code inside expressions

## Files to Modify

- `editors/zed-lustre/extension.toml` - Update with correct metadata
- `editors/zed-lustre/README.md` - Complete documentation
- `editors/zed-lustre/languages/lustre/config.toml` - Language configuration
- `editors/zed-lustre/languages/lustre/highlights.scm` - Copy from tree-sitter
- `editors/zed-lustre/languages/lustre/brackets.scm` - Bracket definitions
- `editors/zed-lustre/languages/lustre/indents.scm` - Indentation rules

## References

- [Zed Extension Documentation](https://zed.dev/docs/extensions)
- [Zed Language Extensions](https://zed.dev/docs/extensions/languages)
- [Example: zed-svelte](https://github.com/zed-extensions/svelte)
