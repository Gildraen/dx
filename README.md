# dx

Shared, versioned, consumable developer experience (DX) for Gildraen
repositories.

**Principle: reference / consume / install the DX, don't copy it.** A
consumer repository keeps only what is genuinely project-specific, plus the
small bootstrap files that a few tools still require locally.

## What it provides

- A Dev Container **Feature** (`ghcr.io/gildraen/dx/dx:1.0.0`) that installs the
  shared runtime (agent instructions, the portable `dx-mcp` launcher, and
  Task helpers) to
  `DX_HOME` (`/opt/dx`).
- **Reusable GitHub Actions workflows** for the `validate`/`maintenance`
  contracts (`.github/workflows/reusable-*.yml`).
- A **Renovate preset** (`default.json`) consumer repositories extend.
- A **Remote Taskfile** of small, generic helpers
  (`.devcontainer/src/dx/runtime/taskfiles/base.yml`).

The `dx-mcp github` command is a small portable entry point for GitHub's
official MCP server. It runs the official
`ghcr.io/github/github-mcp-server:v1.10.1` image via Docker. Authentication is
handled by the official server; DX stores no token. A temporary test image can
be selected with `GITHUB_MCP_IMAGE`, without changing the consumer.

See [docs/architecture.md](docs/architecture.md) for the full model.

## How a repository consumes `dx`

```jsonc
// .devcontainer/devcontainer.json
"features": {
  "ghcr.io/gildraen/dx/dx:1.0.0": {}
}
```

```yaml
# .github/workflows/validate.yml
jobs:
  validate:
    uses: Gildraen/dx/.github/workflows/reusable-validate.yml@v1.0.0
```

```jsonc
// renovate.json
{ "extends": ["github>Gildraen/dx#v1.0.0"] }
```

Full walkthrough: [docs/consumer.md](docs/consumer.md). Minimal working
example: [examples/consumer/](examples/consumer/).

## Releases

`dx` is versioned with SemVer tags (`vX.Y.Z`). Before tagging, update the
Feature manifest to the same version, for example `"version": "1.1.0"`, then
push `v1.1.0`. The release workflow fails if they differ, publishes the
Feature to GHCR, and creates a GitHub release. The official Feature action
publishes the SemVer major, minor, and patch tags. Consumers in this repository
are pinned to `ghcr.io/gildraen/dx/dx:1.0.0`; Renovate can propose upgrades to
new exact versions.

## Developing a DX change (dogfood)

Changes to `dx` are validated in a real consumer repository before release,
using a **git worktree** (`project/.dx`), not a copy. See
[docs/dogfood.md](docs/dogfood.md) for the exact procedure.

## Migrating existing repositories

`Niki`, `infra`, `local-llm`, etc. are migrated one at a time from the old
copy/propagation model. See [docs/migration.md](docs/migration.md).

## Repository layout

```
.devcontainer/src/dx/    Dev Container Feature source (devcontainer-feature.json, install.sh, runtime/)
.github/workflows/       validate/maintenance (dx itself) + reusable-* (consumers) + release
test/dx/                 Feature test + small runtime/taskfile/JSON/workflow checks
examples/consumer/       minimal example of a repository consuming dx
docs/                    architecture, consumer guide, dogfood guide, migration guide
default.json             Renovate preset consumed by other repositories
renovate.json            dx's own Renovate config
Taskfile.yml             tasks to work on dx itself (validate, test, feature:test, status, archive)
```

## Useful commands

```sh
task --list
task validate
task test
task feature:test
task status
```
