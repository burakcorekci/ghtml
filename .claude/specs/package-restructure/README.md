# Package Restructure

## Overview

Restructure ghtml internals to support multiple codegen backends (Lustre, StringTree, String, future reactive). This involves cleaning up the AST to be backend-agnostic, splitting the parser into separate lexer and parser modules, and introducing a target dispatch system in codegen.

**Scope:** Internal refactoring within the single `ghtml` package. Package extraction (ghtml_core, ghtml_lustre) is future work enabled by but not part of this spec.

**Supersedes:** `.claude/specs/multi_target_architecture/` — this spec extends that design with AST cleanup and parser split requirements.

## Requirements

See `requirements.md` for EARS-formatted requirements.

## Design

See `design.md` for architecture and technical decisions.

## Research

See `research/` for investigation notes:
- `coupling_analysis.md` — Module dependency analysis of current codebase

## Related Tasks

Query with: `bd list --json | jq '.[] | select(.labels[]? | contains("spec:package-restructure"))'`
