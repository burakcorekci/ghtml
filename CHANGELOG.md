# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - 2026-02-01

### Added
- Initial release
- Template syntax: `@import`, `@params`, expression interpolation `{expr}`
- Control flow: `{#if}`, `{#each}`, `{#case}` blocks
- Event handlers: `@click`, `@input`, `@change`, `@submit`, etc.
- Attribute support: static, dynamic, and boolean attributes
- Custom element support (tags with hyphens use `element()`)
- Watch mode (`--watch`) for automatic regeneration during development
- Hash-based caching for incremental builds
- Orphan file cleanup (`--clean`)
- Force regeneration (`--force`)
