# Epic: Editor Support

## Goal

Provide syntax highlighting and editor integration for `.lustre` template files across major code editors, enabling a better developer experience when working with Lustre templates.

## Background

The `.lustre` template format combines:
- Directives: `@import()`, `@params()`
- HTML-like tags with attributes
- Expression interpolation: `{expression}`
- Control flow blocks: `{#if}`, `{#each}`, `{#case}`
- Event handlers: `@click={}`, `@input={}`
- Gleam type annotations in params

Without proper syntax highlighting, developers must work with plain text files, making templates harder to read and maintain. By providing editor support, we improve the developer experience significantly.

## Scope

### In Scope
- Tree-sitter grammar for `.lustre` files (foundation for modern editors)
- Zed extension using tree-sitter
- TextMate grammar for broader editor compatibility
- VS Code extension using TextMate grammar
- Directory structure that allows independent publishing

### Out of Scope
- Language Server Protocol (LSP) implementation (future epic)
- Autocompletion and diagnostics (requires LSP)
- JetBrains native plugin (can use TextMate bundle)
- Vim/Neovim dedicated plugin (can use tree-sitter directly)
- Formatting/auto-indent rules (future enhancement)

## Design Overview

Editor support lives in `editors/` directory with each package independently publishable:

```
editors/
├── tree-sitter-lustre/       # npm: tree-sitter-lustre
│   ├── grammar.js            # Grammar definition
│   ├── package.json
│   ├── queries/
│   │   └── highlights.scm    # Highlighting queries
│   └── src/                   # Generated parser (gitignored)
│
├── vscode-lustre/            # VS Code Marketplace
│   ├── package.json
│   ├── syntaxes/
│   │   └── lustre.tmLanguage.json
│   └── language-configuration.json
│
└── zed-lustre/               # Zed Extensions
    ├── extension.toml
    ├── languages/
    │   └── lustre/
    │       └── config.toml
    └── grammars/             # Links to tree-sitter
```

## Task Breakdown

| # | Task | Description | Dependencies |
|---|------|-------------|--------------|
| 001 | Directory Structure | Set up editors/ directory with package scaffolding | None |
| 002 | Tree-sitter Grammar | Implement tree-sitter-lustre grammar | 001 |
| 003 | Zed Extension | Create Zed extension using tree-sitter | 002 |
| 004 | TextMate Grammar | Create TextMate grammar for VS Code compatibility | 001 |
| 005 | VS Code Extension | Package VS Code extension with TextMate grammar | 004 |

## Task Dependency Graph

```
        001_directory_structure
               /          \
              v            v
002_tree_sitter_grammar   004_textmate_grammar
              |                    |
              v                    v
     003_zed_extension    005_vscode_extension
```

## Success Criteria

1. `.lustre` files have syntax highlighting in Zed editor
2. `.lustre` files have syntax highlighting in VS Code
3. Tree-sitter grammar correctly parses all test fixtures
4. Each editor package can be independently published
5. Syntax highlighting covers: directives, HTML tags, expressions, control flow, event handlers

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Tree-sitter grammar complexity | Medium | Start with basic syntax, iterate |
| TextMate regex limitations | Low | Accept some edge cases may not highlight perfectly |
| Editor API changes | Low | Pin to stable versions, test before updates |

## Open Questions

- [x] Priority order for editor support → tree-sitter > zed > textMate > vscode
- [ ] Should we publish to npm/VS Code Marketplace immediately or wait for stability?
- [ ] Include Neovim queries in tree-sitter package or separate?

## References

- [Tree-sitter documentation](https://tree-sitter.github.io/tree-sitter/)
- [Zed extension docs](https://zed.dev/docs/extensions)
- [VS Code Language Extension Guide](https://code.visualstudio.com/api/language-extensions/overview)
- [TextMate Language Grammars](https://macromates.com/manual/en/language_grammars)
