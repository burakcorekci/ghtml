# Epic: Learning Examples

## Goal

Create a series of 8 progressive examples that teach users how to use the Lustre Template Generator, from basic usage to advanced features including control flow, event handling, web components, and styling. Ensure all examples are validated by CI.

## Background

The project currently has a single `examples/simple/` example that demonstrates basic string interpolation. Users need comprehensive examples to learn all template features: attributes, event handlers (both patterns), control flow constructs, web component integration (Shoelace and Material Web), and Tailwind CSS styling.

## Scope

### In Scope
- 8 example projects with increasing complexity
- README documentation for each example
- Working Lustre applications that can be run in browser
- Coverage of all template syntax features

### Out of Scope
- Server-side rendering examples
- Production deployment configurations
- Mobile-specific examples
- Non-Lustre frontend frameworks

## Design Overview

Each example is a standalone Gleam/Lustre project demonstrating specific features:

```
examples/
├── 01_simple/              # Basic: params, static attrs, text interpolation
├── 02_attributes/          # Static, dynamic, boolean attributes
├── 03_events/              # Both handler patterns: reference vs call
├── 04_control_flow/        # {#if}, {#each}, {#case}
├── 05_shoelace/            # Shoelace web components
├── 06_material_web/        # Material Web components
├── 07_tailwind/            # Tailwind CSS utility classes
└── 08_complete/            # Combined Task Manager app
```

Each example follows this structure:
```
XX_name/
├── README.md                # Concepts, setup, exercises
├── gleam.toml               # Project config with HTML settings
├── manifest.toml            # Locked dependencies
├── assets/
│   └── styles.css           # Custom styles (if needed)
└── src/
    ├── app.gleam            # Main Lustre app
    ├── types.gleam          # Shared types (if needed)
    └── components/
        └── *.lustre         # Template components
```

## Task Breakdown

| # | Task | Description | Dependencies |
|---|------|-------------|--------------|
| 001 | Rename simple example | Rename `simple/` to `01_simple/`, add README | None |
| 002 | Create attributes example | Static, dynamic, boolean attrs | 001 |
| 003 | Create events example | Both handler patterns | 001 |
| 004 | Create control flow example | if/each/case constructs | 001 |
| 005 | Create Shoelace example | Shoelace web components | 001 |
| 006 | Create Material Web example | Material Web components | 001 |
| 007 | Create Tailwind example | Tailwind CSS integration | 001 |
| 008 | Create complete example | Combined Task Manager app | 002-007 |
| 009 | Add CI validation | Update check/ci to validate examples build | 001-008 |

## Task Dependency Graph

```
              001_rename_simple
                     │
    ┌────────┬───────┼───────┬────────┬────────┐
    │        │       │       │        │        │
    v        v       v       v        v        v
  002      003     004     005      006      007
   │        │       │       │        │        │
   └────────┴───────┴───────┴────────┴────────┘
                     │
                     v
                   008
                     │
                     v
                   009
```

## Success Criteria

1. All 8 examples build successfully with `gleam build`
2. All examples run in browser with `gleam run -m lustre/dev start`
3. Generated `.gleam` files compile without errors
4. Each README clearly explains the concepts demonstrated
5. Examples progressively build on previous concepts
6. `just check` and `just ci` validate all examples build

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Web component CDNs may change | Medium | Pin specific versions in gleam.toml |
| Lustre dev tools version incompatibility | Medium | Test with current lustre_dev_tools version |
| Complex examples may be hard to follow | Low | Keep each example focused on 1-2 concepts |

## Open Questions

- [x] Include both Material Web and Shoelace? **Yes, separate examples**
- [x] Add README to each example? **Yes**
- [x] Include combined final example? **Yes, 08_complete**

## References

- [Lustre documentation](https://hexdocs.pm/lustre/)
- [Shoelace components](https://shoelace.style/)
- [Material Web components](https://material-web.dev/)
- [Tailwind CSS](https://tailwindcss.com/)
