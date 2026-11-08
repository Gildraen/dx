# dx

Shared, consumable developer experience (DX) for Gildraen
repositories.

A consumer repository references shared workflows, Task helpers and the Renovate
preset, and installs the runtime through the Dev Container Feature. Its bootstrap
files and project-specific configuration remain in that repository.

## Shared tool baseline

The Feature provides Node.js LTS, GitHub CLI, Go Task, Git, `jq`, ripgrep and
`libatomic1` through its declared Feature dependencies. See
[docs/architecture.md](docs/architecture.md#shared-tool-baseline).

## What it provides

- A Dev Container **Feature** (`ghcr.io/gildraen/dx/dx:<released-version>`) that
  installs the shared runtime (agent instructions, skills, the portable `dx-mcp` launcher,
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
then lists roles in `agents/*.agent.md` and workflows in `skills/*/SKILL.md` by their
`name` and `description` metadata. Directory contents are authoritative.

Consumer repositories keep all project-specific roles in `.agents/agents/`
and skills in `.agents/skills/`; these are their sole canonical locations.
The runtime bootstrap lists and loads relevant resources there alongside the
shared resources in `DX_HOME`. The DX Feature adds `.agents/agents/` to the
VS Code agent picker with `chat.agentFilesLocations`. This DX checkout adds its
runtime agent directory to the same VS Code setting in
`.devcontainer/devcontainer.json`; consumer repositories do not inherit that
checkout-specific path. The Feature does not modify Copilot user directories.
For other clients, the project `AGENTS.md` bootstrap remains the explicit loading path.
If a client does not read that file, provide it in the context or initial
request.
Subagents are used only when the client supports them; otherwise the current
agent applies the selected role and reports that fallback.

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
  "ghcr.io/gildraen/dx/dx:<released-version>": {}
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

The Feature uses published OCI versions; workflows, Taskfiles and the preset
use existing Git references managed separately. Feature publication does not
create Git tags for these components.
Renovate proposes upgrades afterwards. Full walkthrough:
[docs/consumer.md](docs/consumer.md).

## Releases

Every push to `main` runs the release workflow. Choose a new stable version in
the Feature manifest and update the consumer example before merging. The
workflow only checks out the pushed commit and calls the native Dev Containers
action to publish the Feature to GHCR. The action and its CLI are pinned.
Version selection is manual; the CLI skips an already published Feature
version. Publication produces OCI artifacts without Git tags or GitHub releases.
Validation and container tests stay in PR CI. A new push cancels the previous
run; a rerun does not guarantee repair of partially updated OCI aliases.

See [the component reference](docs/decoupage.md) for the boundaries
between Feature, IA resources, MCP, Task, workflows and Renovate.

This repository's own devcontainer
consumes the Feature from local source (`./src/dx`), not a published release;
external consumers select a published Feature version and Renovate proposes upgrades.
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

See [docs/migration.md](docs/migration.md) for the integration procedure for an
existing repository.

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
