# Consuming `dx`

This describes how a repository consumes the stable, released version of
`dx`. For working on `dx` itself using a real project as a testbed, see
[dogfood.md](dogfood.md).

## 1. Dev Container Feature

Compose the official Features you need with the shared `dx` Feature:

```jsonc
// .devcontainer/devcontainer.json
{
  "name": "my-project",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu-24.04",
  "features": {
    "ghcr.io/devcontainers/features/node:2": { "version": "lts" },
    "ghcr.io/devcontainers/features/github-cli:1": {},
    "ghcr.io/devcontainers-extra/features/go-task:1": { "version": "3.53.0" },
    "ghcr.io/devcontainers/features/docker-outside-of-docker:1": {},
    "ghcr.io/gildraen/dx/dx:1.0.0": {}
  }
}
```

Only add other official Features (docker-outside-of-docker, apt packages,
language runtimes, …) if your project actually needs them. `dx` does not
bundle them.

This installs the DX runtime at `/opt/dx` (`DX_HOME`): shared agent
instructions, the portable `dx-mcp` launcher, and Task helpers. The launcher
runs GitHub's pinned official MCP image
`ghcr.io/github/github-mcp-server:v1.10.1` through Docker and does not manage a
GitHub token. To test another image temporarily, run
`GITHUB_MCP_IMAGE=ghcr.io/github/github-mcp-server:test dx-mcp github`; the
consumer configuration remains unchanged. The Dev Container keeps its `gh`
configuration under
`.devcontainer/.gh`; the authentication file there is ignored locally.

## 2. Reusable GitHub workflows

```yaml
# .github/workflows/validate.yml
name: validate
on:
  pull_request:
jobs:
  validate:
    uses: Gildraen/dx/.github/workflows/reusable-validate.yml@v1.0.0
```

The reusable workflow runs `task validate` (configurable via the `task-name`
input) in your repository. Your `Taskfile.yml` defines what `validate` (and
`test`, `lint`, …) means for your stack — `dx` only enforces the contract,
not the implementation. It sets `TASK_REMOTE_TRUSTED_HOSTS=github.com` for
the remote DX Taskfile, avoiding an interactive trust prompt in CI without
enabling global `--yes` behavior.

Same pattern for maintenance / link-checking:
`Gildraen/dx/.github/workflows/reusable-maintenance.yml@v1.0.0`.

## 3. Remote Taskfile (optional shared helpers)

```yaml
# Taskfile.yml
includes:
  dx: https://github.com/Gildraen/dx.git//src/dx/runtime/taskfiles/base.yml?ref=v1.0.0
```

Gives you `task dx:doctor` and `task dx:mcp:github`. Your own
`validate`/`test`/`lint` tasks stay in your Taskfile.

Remote Taskfiles require Go Task `v3.53.0` or newer. This is the first stable
release where Remote Taskfiles are generally available, so the Dev Container
pins that minimum version.

The first released consumer ref is shown as `v1.0.0`; it must exist as a DX
tag before the consumer is used. CI downloads that exact ref and trusts only
`github.com` through `TASK_REMOTE_TRUSTED_HOSTS=github.com`.

## 4. Renovate preset

```jsonc
// renovate.json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["github>Gildraen/dx#v1.0.0"]
}
```

Renovate then proposes updates to: the `dx` Feature version in
`devcontainer.json` (native devcontainer manager), reusable workflow refs
(native github-actions manager), and the Remote Taskfile ref (a single
regex-based custom manager, documented in `default.json`, kept because Task
has no native Renovate manager).

## 5. `AGENTS.md`

Keep it small: reference the shared instructions, then list only what is
truly project-specific.

```markdown
# Project agent instructions

Load the shared DX agent instructions first:
- when a DX dogfood checkout exists (`./.dx/src/dx/runtime/agents/`), use it;
- otherwise use the installed runtime (`$DX_HOME/agents/`, `/opt/dx/agents/`).

Then apply the project-specific rules below.

## Project-specific rules
...
```

See [examples/consumer/](../examples/consumer/) for a full minimal example.

## Runtime state that never belongs in `dx` or in your repository

Tokens, `gh` auth state, and generated MCP configuration are runtime state, not
the DX baseline. `gh` state is isolated under `.devcontainer/.gh` and ignored.
The official GitHub MCP server's local stdio OAuth flow keeps its token in
memory only, so no MCP token file or workspace state directory is required. DX
uses OAuth as its single authentication mode.
