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
  installs the DX-maintained snapshots of `Gildraen/dx-agents` and
  `Gildraen/dx-tools` in `/opt/dx/components/agents` and
  `/opt/dx/components/tools`, plus the `dx-mcp` wrapper. `DX_HOME=/opt/dx`
  retains compatibility paths through symlinks.
- **Reusable GitHub Actions workflows** from `Gildraen/ci-workflows` for
  `validate`, devcontainer tests and maintenance; the DX-specific
  `reusable-feature-test.yml` stays in this repository. Three DX compatibility
  wrappers delegate to the external workflows at a fixed commit SHA with the version tag in a comment, without copying
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
Subagents are used only when the client supports them; otherwise the agent
applies the selected role and reports that fallback.

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
    uses: Gildraen/ci-workflows/.github/workflows/reusable-validate.yml@<ci-workflow-commit-sha> # <ci-workflow-tag>
```

Component revisions are fixed in the DX Feature source and are not exposed as
Feature options. CI workflow calls and Remote Taskfile includes use separate
refs that consumers pin independently; Renovate configuration for those refs
is separate. Feature publication does not create Git refs for these components.
Full walkthrough:
[docs/consumer.md](docs/consumer.md).

## Releases

After all validation jobs succeed on a push to `main`, Release Please opens or
updates a release PR from Conventional Commits. The repository tag omits the
`v` prefix. Merging the release PR updates `version.txt` and the Feature
manifest together; the existing [release workflow](.github/workflows/release.yml)
then publishes that Feature version to GHCR. Feature OCI publication and Git
tag creation remain separate outputs. Existing `v` tags are not renamed. The
release job calls the shared Release Please workflow pinned to ci-workflows
commit `4b4026ff669b5fe8da2aa83e216591bb09e1e8a1` (future tag `0.2.0`).

The baseline is `1.3.0`. Release Please and Renovate pins use the shared preset
version `0.2.0`; merge this PR only after that preset release is published.
Publish ci-workflows `0.2.0` before merging this PR so the shared release
workflow ref is available.
Configure `RELEASE_PLEASE_TOKEN` as a fine-grained repository secret if Actions
should trigger CI automatically on the release PR. GitHub suppresses workflow
runs for pull requests created with `GITHUB_TOKEN`; without the secret, required
PR checks may not run and must be handled before merging.

See [the component reference](docs/decoupage.md) for the boundaries
between Feature, IA resources, MCP, Task and workflows.

This repository's own devcontainer consumes the Feature from local source
(`./src/dx`), not a published release; external consumers select a published
Feature release. Component revisions are maintained in DX and delivered to
consumers through a Feature release; consumers do not configure component refs.

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
