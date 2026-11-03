# dx

Shared, consumable developer experience (DX) for Gildraen
repositories.

**Principle: reference / consume / install the DX, don't copy it.** A
consumer repository keeps only what is genuinely project-specific, plus the
small bootstrap files that a few tools still require locally.

## Shared tool baseline

`dx` also defines a small common tool baseline for Gildraen projects, admitted
only when a shared DX contract requires a tool or it is expected to be used
durably across most projects — see
[docs/architecture.md](docs/architecture.md#shared-tool-baseline) for the
current list, the admission policy, and why each tool qualifies.

## What it provides

- A Dev Container **Feature** (`ghcr.io/gildraen/dx/dx`) that installs the
  shared runtime (agent instructions, skills, the portable `dx-mcp` launcher,
  and Task helpers) to
  `DX_HOME` (`/opt/dx`).
- **Reusable GitHub Actions workflows** for the `validate`/`maintenance`
  contracts (`.github/workflows/reusable-*.yml`).
- The `dx` CI keeps structural validation on the runner, runs `task test` in
  this repository's devcontainer, and runs the Feature tests directly on the
  runner's Docker daemon.
- A **Renovate preset** (`default.json`) consumer repositories extend.
- A **Remote Taskfile** of small, generic helpers
  (`.devcontainer/src/dx/runtime/taskfiles/base.yml`).

The runtime is independent of the AI client, model, and editor. A small project
`AGENTS.md` resolves `DX_HOME` from the environment (default `/opt/dx` when
absent) and asks the agent to read that runtime's `AGENTS.md`. The runtime
explicitly loads `instructions/base.md` and `instructions/git.md` before work,
then lists roles in `agents/*.md` and workflows in `skills/*/SKILL.md` by their
`name` and `description` metadata. Directory contents are authoritative.

Consumer repositories may add project-specific roles in `.agents/agents/`
and skills in `.agents/skills/`; their bootstrap asks the agent to list and
read relevant resources there too. These paths and `DX_HOME` do not configure
a client's native picker or guarantee automatic loading. If a client does not
read the project's `AGENTS.md`, provide it explicitly in the context or initial
request. Subagents are used only when the client supports them; otherwise the
current agent applies the selected role and reports that fallback.
`.agents/mcp.json` is reserved for a future MCP configuration standard and is
not part of the current contract.

The `dx-mcp github` command is a small portable entry point for GitHub's
official MCP server. It runs a pinned version of the official
`ghcr.io/github/github-mcp-server` image via Docker. Authentication is
handled by the official server; DX stores no token. The image tag is pinned in
the script and kept current by Renovate, not configurable per consumer.

See [docs/architecture.md](docs/architecture.md) for the full model.

## How a repository consumes `dx`

```jsonc
// .devcontainer/devcontainer.json
"features": {
  "ghcr.io/gildraen/dx/dx:<released-tag>": {}
}
```

```yaml
# .github/workflows/validate.yml
jobs:
  validate:
    uses: Gildraen/dx/.github/workflows/reusable-validate.yml@<released-tag>
```

```jsonc
// renovate.json
{ "extends": ["github>Gildraen/dx#<released-tag>"] }
```

Use the same existing release tag for the Feature, workflows, and preset;
Renovate proposes upgrades afterwards. Full walkthrough:
[docs/consumer.md](docs/consumer.md).

## Releases

Before publishing, the Feature manifest and Git release tag must identify the
same release; CI rejects a mismatch. The release workflow publishes the
Feature to GHCR and creates a GitHub release. This repository's own devcontainer
consumes the Feature from local source (`./src/dx`), not a published release;
external consumers pin a release tag and let Renovate propose upgrades.
The installed runtime is a snapshot: shared resource changes require updating
the Feature release and rebuilding the consumer container to take effect.

## Developing a DX change (dogfood)

Changes to `dx` are validated in a real consumer repository before release,
using a **git worktree** (`project/.devcontainer/.dx`), not a copy. See
[docs/dogfood.md](docs/dogfood.md) for the exact procedure.
Dogfood selects the live runtime through `remoteEnv.DX_HOME`; the project
bootstrap reads it directly, without client-specific adapters or discovery
settings. In this repository, `remoteEnv.DX_HOME` points at
`${containerWorkspaceFolder}/.devcontainer/src/dx/runtime`, and the root
[AGENTS.md](AGENTS.md) links directly to that runtime's entry point.

## Migrating existing repositories

Consumer repositories are migrated one at a time from the old copy/propagation
model. See [docs/migration.md](docs/migration.md) for the current list and
procedure.

## Repository layout

```
.devcontainer/src/dx/    Dev Container Feature source (devcontainer-feature.json, install.sh, runtime/)
.github/workflows/       validate/maintenance (dx itself) + reusable-* (consumers) + release
.devcontainer/test/dx/   Feature test + small runtime/taskfile/JSON/workflow checks
docs/                    architecture, consumer guide, dogfood guide, migration guide
default.json             Renovate preset consumed by other repositories
renovate.json            dx's own Renovate config
Taskfile.yml             tasks to work on dx itself (validate, test, feature:test)
```

## Useful commands

```sh
task --list
task validate
task test                 # inside the dx devcontainer
task feature:test         # directly on a host with Docker
```
