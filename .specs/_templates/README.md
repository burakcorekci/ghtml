# [Feature Name]

## Overview
[Brief description of what this feature does]

## Requirements
See `requirements.md` for EARS-formatted requirements.

## Design
See `design.md` for architecture and technical decisions.

## Research
See `research/` for investigation notes and alternatives analysis.

## Related Tasks
Query with: `bd list --json | jq '.issues[] | select(.meta.spec_dir == ".specs/[feature]")'`
