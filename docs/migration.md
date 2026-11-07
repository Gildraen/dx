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
| `.tools/install-tools.sh` | remplacé par la Dev Container Feature `ghcr.io/gildraen/dx/dx:<released-tag>` |
| `.tools/ollama/` | supprimé de la baseline commune — à gérer par projet si nécessaire, hors `dx` |
| `.bin/mcp-run` | `dx-mcp github` (wrapper portable du serveur officiel GitHub MCP) |
| `.tools/mcp-server-github/` | supprimé — `dx-mcp` utilise l'image Docker officielle versionnée avec OAuth |
| `.agents/rules/git.md` | `.devcontainer/src/dx/runtime/instructions/git.md` (runtime partagé, chargé explicitement par son `AGENTS.md`) |
| skills communes copiees | `.devcontainer/src/dx/runtime/skills/` (runtime partage) |
| gros `AGENTS.md` copié | bootstrap local court + runtime partagé (`$DX_HOME`) |
| agents projet | `.agents/agents/` dans le repository consommateur |
| skills projet | `.agents/skills/` dans le repository consommateur |
| futur `mcp.json` | `.agents/mcp.json` quand le contrat sera defini |
| `Taskfile.yml` partagé par copie | Remote Taskfile (`.devcontainer/src/dx/runtime/taskfiles/base.yml`) |
| `validate.yml` copié | `uses: Gildraen/dx/.github/workflows/reusable-validate.yml@<released-tag>` |
| `maintenance.yml` copié | `uses: Gildraen/dx/.github/workflows/reusable-maintenance.yml@<released-tag>` |
| `renovate.json` copié | `"extends": ["github>Gildraen/dx#<released-tag>"]` |
| devcontainer complet copié | petit `devcontainer.json` composant des Features officielles + `ghcr.io/gildraen/dx/dx:<released-tag>` |

The shared Feature carries the common tool baseline declared in its manifest:
Node.js LTS, GitHub CLI, Go Task, `jq`, and ripgrep. Do not keep separate
consumer Feature entries for those tools unless a repository needs a different
project-specific version. Docker-outside-of-Docker remains
project-specific until the future `.agents/mcp.json` contract is defined.

## Per-repository steps

1. **Pick a released `dx` tag** that provides the tools required by the consumer.
2. **Devcontainer**: replace the copied devcontainer.json with a short one
   composing official Features plus `ghcr.io/gildraen/dx/dx:<released-tag>` (see
   [docs/consumer.md](consumer.md)). Keep only Features actually needed by
   that project in addition to the selected DX Feature release.
3. **AGENTS.md**: replace the full copy with the bootstrap pattern documented
   in [docs/consumer.md](consumer.md), then keep only the rules genuinely
   specific to that repository below it. Keep common
   skills in `dx` and project-specific agents under `.agents/agents/` and
   skills under `.agents/skills/` in the consumer repository. The bootstrap
   resolves `DX_HOME` from the environment (default `/opt/dx` when absent) and
   reads that runtime's `AGENTS.md`, which explicitly loads
   `instructions/base.md` and `instructions/git.md` before work. It then lists
   roles in `agents/*.agent.md` and workflows in `skills/*/SKILL.md` by their `name`
   and `description`; directory contents are authoritative. The runtime then
   explicitly lists and loads project resources only from `.agents/agents/`
   and `.agents/skills/`, the sole canonical project locations. Do not keep
   duplicate project copies in client-specific directories or configure
   per-consumer discovery settings. The Feature contributes the supported
   VS Code `chat.agentFilesLocations` setting for `.agents/agents/`; it does
   not make that editor-specific setting available to Copilot CLI or the
   Copilot app. It does not set the deprecated `chat.agentSkillsLocations`.
   The Feature does not install shared resources into Copilot user directories.
   The DX checkout adds its source runtime path to the VS Code
   `chat.agentFilesLocations` setting in `.devcontainer/devcontainer.json`;
   consumer repositories do not inherit that checkout-specific path, and it
   cannot point to the Feature's installed `/opt/dx` runtime. Shared resources
   are loaded through the runtime bootstrap. The Feature installs the routing
   instructions and sets `DX_HOME` through `containerEnv`.
   If the client does not read `AGENTS.md`, provide it explicitly through
   context or the initial request. Delegate only when subagents are supported;
   otherwise apply the role in the current agent and report that fallback.
   Remove only obsolete DX-managed files; preserve project-specific resources. Leave
   `.agents/mcp.json` absent until the MCP contract is defined in `dx`.
4. **Taskfile.yml**: remove any copied generic tasks. Add the Remote
   Taskfile include for `dx` helpers if useful. Keep the project's own
   `validate`/`test`/`lint` implementations.
5. **GitHub workflows**: replace copied `validate.yml`/`maintenance.yml`
   with thin wrappers calling the reusable workflows.
6. **renovate.json**: replace the copied config with
   `{ "extends": ["github>Gildraen/dx#<released-tag>"] }`, then add anything truly
   project-specific.
7. **Remove now-unused local files**: `.tools/`, `.bin/mcp-run`, obsolete
   DX-managed agent files, and any dx-drift-related workflow or issue
   automation specific to that repository. Do not remove project-specific
   `.agents/agents/` or `.agents/skills/`; those are the only canonical project
   locations and should not be duplicated into client-specific directories.
8. **Validate**: run `task validate` / CI in the migrated repository before
   merging.
9. **Repeat** for the next repository. There is no bulk/automatic migration
   tool — each repository is migrated with a normal PR.

## After migration

- `dx` releases a new version → Renovate opens PRs in `Niki`, `infra`,
  `local-llm`, etc. to bump the Feature version, the reusable workflow refs,
  and the Renovate preset tag.
- To test a `dx` change live in one of these repositories before release,
   use the [dogfood workflow](dogfood.md): set `remoteEnv.DX_HOME` to
   `${containerWorkspaceFolder}/.devcontainer/.dx/.devcontainer/src/dx/runtime`
   and let the project bootstrap read it directly, without discovery settings.
- Stable runtime resources are an installed snapshot. Updating the Feature
   release and rebuilding the consumer container is required to receive changes.
