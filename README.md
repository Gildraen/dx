# dx

Canonical development-experience baseline shared across Gildraen repositories.

This repository is the source of truth for common tooling, devcontainer defaults, CI checks, and maintenance automation.

## Goal

- Keep all project repositories aligned on a common DX baseline
- Reduce drift between repos
- Make updates in one place, then propagate safely

## Scope

- `.devcontainer/` baseline
- GitHub Actions templates and validation workflows
- Renovate baseline rules
- Agent contribution guardrails (`.agents/`)

## Operating Model

1. Update DX policy/files in this repository
2. Propagate equivalent updates to target repositories (`Niki`, `infra`, `local-llm`, etc.)
3. Validate per-repo with local tasks and CI
4. Keep periodic coherence checks active

## Coherence Strategy

The `dx-coherence` workflow is intended to detect drift from this baseline across repositories.

Recommended policy:

- define canonical file list in this repo
- compare target repos against canonical revisions
- open issue or PR on drift detection

## Baseline Components Present

- Devcontainer baseline (Node LTS, task, gh, docker-outside-of-docker)
- Maintenance workflow (link checks)
- Validation workflow (`task validate`)
- Renovate config including regex managers for tool installers

## Suggested Propagation Rules

- Propagate from `dx` to product/infrastructure repos for:
  - `.devcontainer/devcontainer.json`
  - `.github/workflows/maintenance.yml`
  - `.github/workflows/validate.yml`
  - `renovate.json`
- Keep repo-specific runtime files local (business logic, product specs, service compose details)

## Related Repositories

- `Gildraen/Niki`: product behavior and tests
- `Gildraen/infra`: shared Traefik layer
- `Gildraen/local-llm`: local LLM microservice
