# Task 001: Directory Structure

## Description

Set up the `editors/` directory with the scaffolding for all editor packages. This establishes the foundation for tree-sitter, Zed, TextMate, and VS Code support with proper package.json files and directory structure.

## Dependencies

- None - this is the first task.

## Success Criteria

1. `editors/` directory exists with subdirectories for each editor package
2. Each package has a valid `package.json` or manifest file
3. `.gitignore` properly excludes generated files (node_modules, build artifacts)
4. README files document each package's purpose and usage

## Implementation Steps

### 1. Create Directory Structure

```
editors/
├── README.md                     # Overview of editor support
├── tree-sitter-lustre/
│   ├── package.json
│   ├── grammar.js                # Placeholder
│   ├── queries/
│   │   └── highlights.scm        # Placeholder
│   ├── bindings/
│   │   └── node/
│   │       └── index.js          # Node bindings
│   └── .gitignore
│
├── zed-lustre/
│   ├── extension.toml
│   ├── README.md
│   ├── languages/
│   │   └── lustre/
│   │       └── config.toml
│   └── grammars/
│       └── .gitkeep
│
├── vscode-lustre/
│   ├── package.json
│   ├── README.md
│   ├── syntaxes/
│   │   └── .gitkeep
│   └── language-configuration.json
│
└── .gitignore                    # Shared ignores
```

### 2. Create tree-sitter-lustre package.json

```json
{
  "name": "tree-sitter-lustre",
  "version": "0.1.0",
  "description": "Tree-sitter grammar for Lustre template files",
  "main": "bindings/node",
  "types": "bindings/node",
  "keywords": ["tree-sitter", "lustre", "gleam", "syntax-highlighting"],
  "repository": {
    "type": "git",
    "url": "https://github.com/user/lustre_template_gen",
    "directory": "editors/tree-sitter-lustre"
  },
  "license": "MIT",
  "devDependencies": {
    "tree-sitter-cli": "^0.22.0"
  },
  "scripts": {
    "build": "tree-sitter generate",
    "test": "tree-sitter test",
    "parse": "tree-sitter parse"
  },
  "tree-sitter": [
    {
      "scope": "source.lustre",
      "injection-regex": "^lustre$",
      "file-types": ["lustre"],
      "highlights": "queries/highlights.scm"
    }
  ]
}
```

### 3. Create Zed extension.toml

```toml
id = "lustre"
name = "Lustre Templates"
description = "Syntax highlighting for Lustre template files"
version = "0.1.0"
schema_version = 1
authors = ["Your Name <email@example.com>"]
repository = "https://github.com/user/lustre_template_gen"

[grammars.lustre]
repository = "https://github.com/user/lustre_template_gen"
path = "editors/tree-sitter-lustre"
```

### 4. Create VS Code package.json

```json
{
  "name": "vscode-lustre",
  "displayName": "Lustre Templates",
  "description": "Syntax highlighting for Lustre template files",
  "version": "0.1.0",
  "publisher": "your-publisher",
  "engines": {
    "vscode": "^1.80.0"
  },
  "categories": ["Programming Languages"],
  "contributes": {
    "languages": [{
      "id": "lustre",
      "aliases": ["Lustre", "lustre"],
      "extensions": [".lustre"],
      "configuration": "./language-configuration.json"
    }],
    "grammars": [{
      "language": "lustre",
      "scopeName": "source.lustre",
      "path": "./syntaxes/lustre.tmLanguage.json"
    }]
  }
}
```

### 5. Create editors/.gitignore

```gitignore
# Dependencies
node_modules/

# Build artifacts
tree-sitter-lustre/src/
tree-sitter-lustre/build/
*.wasm

# VS Code
vscode-lustre/*.vsix
vscode-lustre/out/

# Editor-specific
.vscode-test/
```

## Test Cases

This task is infrastructure setup - testing is manual verification:

1. Verify directory structure matches specification
2. Verify `npm install` works in tree-sitter-lustre (should install tree-sitter-cli)
3. Verify JSON files are valid

## Verification Checklist

- [ ] All directories created as specified
- [ ] `tree-sitter-lustre/package.json` is valid JSON
- [ ] `vscode-lustre/package.json` is valid JSON
- [ ] `zed-lustre/extension.toml` is valid TOML
- [ ] `.gitignore` files exclude appropriate patterns
- [ ] README.md files provide clear documentation

## Notes

- Keep placeholder files minimal - they'll be filled in by subsequent tasks
- The tree-sitter `src/` directory is gitignored as it's generated
- Repository URLs need to be updated with actual repo path

## Files to Create

- `editors/README.md`
- `editors/.gitignore`
- `editors/tree-sitter-lustre/package.json`
- `editors/tree-sitter-lustre/grammar.js` (placeholder)
- `editors/tree-sitter-lustre/queries/highlights.scm` (placeholder)
- `editors/tree-sitter-lustre/bindings/node/index.js`
- `editors/tree-sitter-lustre/.gitignore`
- `editors/zed-lustre/extension.toml`
- `editors/zed-lustre/README.md`
- `editors/zed-lustre/languages/lustre/config.toml`
- `editors/vscode-lustre/package.json`
- `editors/vscode-lustre/README.md`
- `editors/vscode-lustre/language-configuration.json`
- `editors/vscode-lustre/syntaxes/.gitkeep`
