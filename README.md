# dx

Shared, consumable developer experience (DX) for Gildraen
repositories.

A consumer repository references shared workflows and Task helpers,
and installs the runtime through the Dev Container Feature. Its bootstrap
files and project-specific configuration remain in that repository.

## Shared tool baseline

The Feature provides Node.js LTS, GitHub CLI, Go Task, Git, `jq`, ripgrep and
`libatomic1` through its declared Feature dependencies. See
[docs/architecture.md](docs/architecture.md#shared-tool-baseline).

## What it provides

- A Dev Container **Feature** (`ghcr.io/gildraen/dx/dx:<released-version>`) that
  installs independent pinned checkouts of `Gildraen/dx-agents` and
  `Gildraen/dx-tools` in `/opt/dx/components/agents` and
  `/opt/dx/components/tools`, plus the `dx-mcp` wrapper. `DX_HOME=/opt/dx`
  retains compatibility paths through symlinks.
- **Reusable GitHub Actions workflows** from `Gildraen/ci-workflows` for
  `validate`, devcontainer tests and maintenance; the DX-specific
  `reusable-feature-test.yml` stays in this repository. Three DX compatibility
  wrappers delegate to the external workflows at a fixed version tag, without copying
  their implementation, for callers using floating DX references.
- The `dx` CI keeps structural validation on the runner, runs `task test` in
  this repository's devcontainer, and runs the Feature tests directly on the
  runner's Docker daemon.
- A **Remote Taskfile** of small, generic helpers
  (`Gildraen/dx-tools`, `taskfiles/base.yml`).

The IA resources are independent of the AI client, model, and editor. A small project
`AGENTS.md` resolves `DX_AGENTS_HOME` from the environment (default
`/opt/dx/components/agents` when absent) and asks the agent to read its `AGENTS.md`. That guide
explicitly loads `instructions/base.md` and `instructions/git.md` before work,
then lists roles in `agents/*.agent.md` and workflows in `skills/*/SKILL.md` by their
`name` and `description` metadata. Directory contents are authoritative.

Consumer repositories keep all project-specific roles in `.agents/agents/`
and skills in `.agents/skills/`; these are their sole canonical locations.
The bootstrap lists and loads relevant resources there alongside the
shared resources in `DX_AGENTS_HOME`. Native discovery uses local paths and
depends on the client; neither a GitHub URL nor an environment variable
registers a native role or skill. The Feature does not modify Copilot user directories.
For other clients, the project `AGENTS.md` bootstrap remains the explicit loading path.
If a client does not read that file, provide it in the context or initial
request.
Subagents are used only when the client supports them; otherwise the current
agent applies the selected role and reports that fallback.

The `dx-mcp github` command is a small portable entry point for GitHub's
official MCP server. It runs a pinned version of the official
`ghcr.io/github/github-mcp-server` image via Docker. Authentication is
handled by the official server; DX stores no token. The image tag is pinned in
the script, not configurable per consumer.

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
    uses: Gildraen/ci-workflows/.github/workflows/reusable-validate.yml@v0.1.0-rc.1
```

The shared components' candidate consumption version is `v0.1.0-rc.1`, a
prerelease, not a stable release. The Feature uses published OCI versions.
Its `agentsRef` and `toolsRef` options select version tags independently;
workflows, Taskfiles and the Renovate preset also select their own version tags.
Feature publication does not create Git tags for
these components. Full walkthrough:
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
between Feature, IA resources, MCP, Task and workflows.

This repository's own devcontainer
consumes the Feature from local source (`./src/dx`), not a published release;
external consumers select a published Feature version.
The installed components are snapshots: changing `agentsRef` or `toolsRef`
and rebuilding updates them without requiring a new Feature release.

## Developing a DX change (dogfood)

Changes to `dx` are validated in a real consumer repository before release,
using a **git worktree** (`project/.devcontainer/.dx`), not a copy. See
[docs/dogfood.md](docs/dogfood.md) for the exact procedure.
Dogfood selects live components through `DX_AGENTS_HOME` and `DX_TOOLS_HOME`.
This repository uses the pinned submodules `.devcontainer/components/agents`
and `.devcontainer/components/tools`; `initializeCommand` runs
`git submodule update --init --recursive`. The root
[AGENTS.md](AGENTS.md) loads the agents submodule directly.

## Migrating existing repositories

See [docs/migration.md](docs/migration.md) for the integration procedure for an
existing repository.

## Repository layout

```
.devcontainer/src/dx/    Dev Container Feature source and installed launcher wrapper
.devcontainer/components/ Pinned dx-agents and dx-tools submodules for dogfood
.github/workflows/       External CI callers, three compatibility wrappers, Feature-test, release
.devcontainer/test/dx/   Feature and integration checks
docs/                    architecture, consumer guide, dogfood guide, migration guide
Taskfile.yml             tasks to work on dx itself (validate, test, feature:test)
```

## Useful commands

```sh
task --list
task validate
task test                 # inside the dx devcontainer
task feature:test         # directly on a host with Docker
```
