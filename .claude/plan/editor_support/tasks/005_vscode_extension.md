# Task 005: VS Code Extension

## Description

Package the TextMate grammar into a complete VS Code extension that can be installed locally or published to the VS Code Marketplace. This provides syntax highlighting for `.lustre` files in VS Code.

## Dependencies

- 004_textmate_grammar - TextMate grammar must be complete

## Success Criteria

1. Extension installs successfully in VS Code
2. `.lustre` files are recognized and highlighted
3. Language configuration provides good editing experience (brackets, comments)
4. Extension can be packaged as `.vsix` for distribution
5. Extension is ready for VS Code Marketplace publishing

## Implementation Steps

### 1. Update package.json

```json
{
  "name": "lustre",
  "displayName": "Lustre Templates",
  "description": "Syntax highlighting for Lustre template files",
  "version": "0.1.0",
  "publisher": "lustre",
  "repository": {
    "type": "git",
    "url": "https://github.com/user/lustre_template_gen",
    "directory": "editors/vscode-lustre"
  },
  "engines": {
    "vscode": "^1.80.0"
  },
  "categories": [
    "Programming Languages"
  ],
  "keywords": [
    "lustre",
    "gleam",
    "template",
    "syntax highlighting"
  ],
  "icon": "icon.png",
  "main": "./out/extension.js",
  "contributes": {
    "languages": [
      {
        "id": "lustre",
        "aliases": ["Lustre", "lustre"],
        "extensions": [".lustre"],
        "configuration": "./language-configuration.json",
        "icon": {
          "light": "./icons/lustre-light.svg",
          "dark": "./icons/lustre-dark.svg"
        }
      }
    ],
    "grammars": [
      {
        "language": "lustre",
        "scopeName": "source.lustre",
        "path": "./syntaxes/lustre.tmLanguage.json"
      }
    ]
  },
  "scripts": {
    "vscode:prepublish": "npm run compile",
    "compile": "echo 'No compilation needed'",
    "package": "vsce package",
    "publish": "vsce publish"
  },
  "devDependencies": {
    "@vscode/vsce": "^2.22.0"
  }
}
```

### 2. Create Language Configuration

`language-configuration.json`:

```json
{
  "comments": {
    "lineComment": "// ",
    "blockComment": ["/* ", " */"]
  },
  "brackets": [
    ["{", "}"],
    ["[", "]"],
    ["(", ")"],
    ["<", ">"]
  ],
  "autoClosingPairs": [
    { "open": "{", "close": "}" },
    { "open": "[", "close": "]" },
    { "open": "(", "close": ")" },
    { "open": "<", "close": ">", "notIn": ["string"] },
    { "open": "\"", "close": "\"", "notIn": ["string"] },
    { "open": "'", "close": "'", "notIn": ["string"] }
  ],
  "surroundingPairs": [
    { "open": "{", "close": "}" },
    { "open": "[", "close": "]" },
    { "open": "(", "close": ")" },
    { "open": "<", "close": ">" },
    { "open": "\"", "close": "\"" },
    { "open": "'", "close": "'" }
  ],
  "colorizedBracketPairs": [
    ["{", "}"],
    ["[", "]"],
    ["(", ")"]
  ],
  "folding": {
    "markers": {
      "start": "^\\s*\\{#(if|each|case)",
      "end": "^\\s*\\{/(if|each|case)\\}"
    }
  },
  "indentationRules": {
    "increaseIndentPattern": "(<[a-zA-Z][^/>]*>(?!.*</)|\\{#(if|each|case)[^}]*\\}|\\{:else\\})\\s*$",
    "decreaseIndentPattern": "^\\s*(</[a-zA-Z]|\\{/(if|each|case)\\}|\\{:else\\})"
  },
  "wordPattern": "[a-zA-Z_][a-zA-Z0-9_]*"
}
```

### 3. Create README

`README.md`:

```markdown
# Lustre Templates for VS Code

Syntax highlighting for [Lustre](https://lustre.build/) template files.

![Syntax Highlighting Example](./images/example.png)

## Features

- Full syntax highlighting for `.lustre` template files
- Support for:
  - Directives (`@import`, `@params`)
  - HTML-like elements and attributes
  - Expression interpolation (`{expression}`)
  - Control flow (`{#if}`, `{#each}`, `{#case}`)
  - Event handlers (`@click`, `@input`)
- Bracket matching and auto-closing
- Code folding for control blocks

## Installation

### From VS Code Marketplace

1. Open VS Code
2. Go to Extensions (Cmd+Shift+X)
3. Search for "Lustre Templates"
4. Click Install

### From VSIX File

1. Download the `.vsix` file from releases
2. In VS Code, run "Extensions: Install from VSIX..."
3. Select the downloaded file

### Development Installation

1. Clone the repository
2. Run `npm install` in `editors/vscode-lustre`
3. Press F5 to launch Extension Development Host
4. Open a `.lustre` file to test

## Syntax Examples

```lustre
@import(gleam/int)
@params(name: String, count: Int)

<div class="greeting">
  <h1>Hello, {name}!</h1>

  {#if count > 0}
    <p>Count: {int.to_string(count)}</p>
  {:else}
    <p>No count</p>
  {/if}
</div>
```

## Related Projects

- [Lustre](https://lustre.build/) - The Gleam web framework
- [Gleam](https://gleam.run/) - The programming language

## License

MIT
```

### 4. Create .vscodeignore

`.vscodeignore`:

```
.gitignore
.vscode/**
node_modules/**
src/**
*.map
.eslintrc.json
tsconfig.json
**/*.ts
```

### 5. Add Icon (Optional)

Create simple icons for the extension:
- `icon.png` - 128x128 extension icon
- `icons/lustre-light.svg` - File icon for light themes
- `icons/lustre-dark.svg` - File icon for dark themes

### 6. Package and Test

```bash
cd editors/vscode-lustre
npm install

# Test locally
code --extensionDevelopmentPath="$(pwd)"

# Package as VSIX
npm run package
# Creates lustre-0.1.0.vsix

# Install VSIX
code --install-extension lustre-0.1.0.vsix
```

## Directory Structure

```
vscode-lustre/
├── package.json
├── README.md
├── CHANGELOG.md
├── LICENSE
├── .vscodeignore
├── language-configuration.json
├── syntaxes/
│   └── lustre.tmLanguage.json
├── icons/                        # Optional
│   ├── lustre-light.svg
│   └── lustre-dark.svg
├── images/                       # For README
│   └── example.png
└── icon.png                      # Extension icon
```

## Test Cases

Manual testing in VS Code:

1. Open `test/fixtures/simple/basic.lustre`
2. Verify syntax highlighting is applied
3. Test bracket matching: place cursor on `{`, verify matching `}` highlighted
4. Test auto-close: type `{`, verify `}` is auto-inserted
5. Test folding: click fold icon next to `{#if}` block
6. Open Command Palette, type "Change Language Mode" - verify "Lustre" appears
7. Create new file, save as `.lustre` - verify highlighting applies

## Verification Checklist

- [ ] `npm install` succeeds
- [ ] Extension loads without errors in Extension Development Host
- [ ] `.lustre` files are associated with Lustre language
- [ ] Syntax highlighting matches expectations
- [ ] Bracket matching works
- [ ] Auto-closing pairs work
- [ ] Code folding works for control blocks
- [ ] `npm run package` creates valid `.vsix`
- [ ] VSIX installs successfully in fresh VS Code
- [ ] README is accurate and helpful

## Notes

- The `publisher` in package.json must match your VS Code Marketplace publisher ID
- For publishing, you need a Personal Access Token from Azure DevOps
- Consider adding a CHANGELOG.md before publishing
- Screenshot for README should show actual highlighting in action

## Files to Modify

- `editors/vscode-lustre/package.json` - Extension manifest
- `editors/vscode-lustre/README.md` - User documentation
- `editors/vscode-lustre/language-configuration.json` - Language settings
- `editors/vscode-lustre/.vscodeignore` - Package exclusions

## Files to Create

- `editors/vscode-lustre/CHANGELOG.md` - Version history
- `editors/vscode-lustre/icon.png` - Extension icon (optional)

## References

- [VS Code Extension Guide](https://code.visualstudio.com/api/get-started/your-first-extension)
- [Language Configuration](https://code.visualstudio.com/api/language-extensions/language-configuration-guide)
- [Publishing Extensions](https://code.visualstudio.com/api/working-with-extensions/publishing-extension)
- [vsce - VS Code Extension CLI](https://github.com/microsoft/vscode-vsce)
