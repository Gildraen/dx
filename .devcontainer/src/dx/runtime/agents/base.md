---
name: dx-base
description: Baseline agent instructions shared across Gildraen repositories.
trigger: always
paths:
  - "**"
---

# DX baseline

## Provenance

These instructions are shared DX runtime resources, versioned in `Gildraen/dx`
(`.devcontainer/src/dx/runtime/agents/`). They are consumed by other repositories either
through the installed DX runtime (`DX_HOME`) or a local `.dx` dogfood checkout.
Do not fork or copy this content into a consumer repository — extend it with a
short, project-specific `AGENTS.md` instead.

## Working agreements

- Prefer small, reviewable changes over large rewrites.
- State assumptions explicitly when requirements are ambiguous instead of
  guessing silently.
- Respect the contracts a repository exposes (for example `task validate`,
  `task test`, `task lint`) rather than assuming a specific implementation.
- Keep secrets, tokens, and authentication state out of versioned files.

See [git.md](git.md) for the Git and review workflow rules.
