# Migration guide

This documents how to migrate `Niki`, `infra`, `local-llm`, and any other
consumer repository from the old copy/propagation model to the new
reference/install model. **No consumer repository is modified by this
task** — this is a guide for a follow-up migration in each of them.

## Mapping: old resource → new resource

| Actuel | Nouveau |
|---|---|
| `.github/dx-targets.json` | supprimé (dx ne connaît plus ses consommateurs) |
| `.github/scripts/dx-propagate.mjs` | supprimé |
| `.github/scripts/dx-check.mjs` | supprimé |
| `.github/workflows/dx-coherence.yml` | supprimé |
| `.github/workflows/dx-propagate.yml` | supprimé |
| `.tools/install-tools.sh` | remplacé par la Dev Container Feature `ghcr.io/gildraen/dx/dx:1.0.0` |
| `.tools/ollama/` | supprimé de la baseline commune — à gérer par projet si nécessaire, hors `dx` |
| `.bin/mcp-run` | `dx-mcp github` (wrapper portable du serveur officiel GitHub MCP) |
| `.tools/mcp-server-github/` | supprimé — `dx-mcp` utilise l'image Docker officielle versionnée avec OAuth |
| `.agents/rules/git.md` | `.devcontainer/src/dx/runtime/agents/git.md` (runtime partagé) |
| gros `AGENTS.md` copié | bootstrap local court + runtime partagé (`$DX_HOME/agents/`) |
| `Taskfile.yml` partagé par copie | Remote Taskfile (`.devcontainer/src/dx/runtime/taskfiles/base.yml`) |
| `validate.yml` copié | `uses: Gildraen/dx/.github/workflows/reusable-validate.yml@vX.Y.Z` |
| `maintenance.yml` copié | `uses: Gildraen/dx/.github/workflows/reusable-maintenance.yml@vX.Y.Z` |
| `renovate.json` copié | `"extends": ["github>Gildraen/dx#vX.Y.Z"]` |
| devcontainer complet copié | petit `devcontainer.json` composant des Features officielles + `ghcr.io/gildraen/dx/dx:1.0.0` |

## Per-repository steps

1. **Pick a released `dx` tag** (start with the first `v1.0.0`).
2. **Devcontainer**: replace the copied devcontainer.json with a short one
   (see [examples/consumer/.devcontainer/devcontainer.json](../examples/consumer/.devcontainer/devcontainer.json)).
   Keep only Features actually needed by that project in addition to
   `ghcr.io/gildraen/dx/dx:1.0.0`.
3. **AGENTS.md**: replace the full copy with the bootstrap pattern from
   [examples/consumer/AGENTS.md](../examples/consumer/AGENTS.md), then keep
   only the rules genuinely specific to that repository below it.
4. **Taskfile.yml**: remove any copied generic tasks. Add the Remote
   Taskfile include for `dx` helpers if useful. Keep the project's own
   `validate`/`test`/`lint` implementations.
5. **GitHub workflows**: replace copied `validate.yml`/`maintenance.yml`
   with thin wrappers calling the reusable workflows.
6. **renovate.json**: replace the copied config with
   `{ "extends": ["github>Gildraen/dx#vX.Y.Z"] }`, then add anything truly
   project-specific.
7. **Remove now-unused local files**: `.tools/`, `.bin/mcp-run`,
   `.agents/`, any dx-drift-related workflow or issue automation specific to
   that repository.
8. **Validate**: run `task validate` / CI in the migrated repository before
   merging.
9. **Repeat** for the next repository. There is no bulk/automatic migration
   tool — each repository is migrated with a normal PR.

## After migration

- `dx` releases a new version → Renovate opens PRs in `Niki`, `infra`,
  `local-llm`, etc. to bump the Feature version, the reusable workflow refs,
  and the Renovate preset tag.
- To test a `dx` change live in one of these repositories before release,
  use the [dogfood workflow](dogfood.md).
