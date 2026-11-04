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
    "ghcr.io/gildraen/dx/dx:1.2.0": {}
  }
}
```

Only add other Features or packages for project-specific requirements
(Docker-outside-of-Docker, project language runtimes, service CLIs, …). The DX
common tool baseline is deliberately limited and does not cover those tools.

The tool baseline is defined by the selected DX Feature's manifest. Check that
manifest before relying on a tool; requirements not included there remain
project-specific.

The Feature copies the versioned DX runtime to `/opt/dx` and sets
`DX_HOME=/opt/dx` through `containerEnv`: the `AGENTS.md` entry point, shared
instructions, roles, skills, the portable `dx-mcp` launcher, and Task helpers.
This environment variable alone does not configure an AI client. The installed
runtime is a snapshot; to consume shared resource changes, update the Feature
release and rebuild the container. For live sources, use [dogfood.md](dogfood.md).
The launcher runs GitHub's pinned official MCP image through Docker and does
not manage a GitHub token. A project that enables MCP must provide Docker
access separately until the `.agents/mcp.json` contract is defined. Renovate
keeps this pin current; the image is not configurable per consumer. The Dev Container keeps
the GitHub CLI available, but DX does not configure or authenticate it. `gh`
uses its normal user-level configuration by default; each consumer manages its
own authentication and may set `GH_CONFIG_DIR` if it needs a custom location.
If that location is inside the workspace, the consumer must ensure it is
ignored by Git.

## 2. Reusable GitHub workflows

```yaml
# .github/workflows/validate.yml
name: validate
on:
  pull_request:
jobs:
  validate:
    uses: Gildraen/dx/.github/workflows/reusable-validate.yml@<released-tag>
```

The reusable workflow runs `task validate` (configurable via the `task-name`
input) in your repository. Your `Taskfile.yml` defines what `validate` (and
`test`, `lint`, …) means for your stack — `dx` only enforces the contract,
not the implementation. It sets `TASK_REMOTE_TRUSTED_HOSTS=github.com` for
the remote DX Taskfile, avoiding an interactive trust prompt in CI without
enabling global `--yes` behavior.

Same pattern for maintenance / link-checking:
`Gildraen/dx/.github/workflows/reusable-maintenance.yml@<released-tag>`.

## 3. Remote Taskfile (optional shared helpers)

```yaml
# Taskfile.yml
includes:
  dx: https://github.com/Gildraen/dx.git//.devcontainer/src/dx/runtime/taskfiles/base.yml?ref=<released-tag>
```

Gives you `task dx:doctor` and `task dx:mcp:github`. Your own
`validate`/`test`/`lint` tasks stay in your Taskfile.

Remote Taskfiles require a Go Task release with remote include support. The DX
Feature and reusable validation workflow both provide a compatible release.

The reusable validation workflow installs a compatible Task release on its GitHub
Actions runner before executing `task validate`. Its availability in CI does
not mean that the local devcontainer already provides it.

The consumer ref must match an existing DX release tag before the consumer is
used. CI downloads that exact ref and trusts only `github.com` through
`TASK_REMOTE_TRUSTED_HOSTS=github.com`.

## 4. Renovate preset

```jsonc
// renovate.json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["github>Gildraen/dx#<released-tag>"]
}
```

Renovate then proposes updates to: the `dx` Feature version in
`devcontainer.json` (native devcontainer manager), reusable workflow refs
(native github-actions manager), and the Remote Taskfile ref (a single
regex-based custom manager, documented in `default.json`, kept because Task
has no native Renovate manager).

## 5. Agents and skills

Keep the root `AGENTS.md` small: a bootstrap plus genuinely project-specific
rules. The runtime does not require a particular AI client, model, or editor.
Use this bootstrap in the consumer:

````markdown
# Project agent instructions

Before any work, resolve DX_HOME from the process environment; use /opt/dx
only when DX_HOME is absent. Read its AGENTS.md and follow the shared guidance.

## Project-specific rules
...
````

Common loading, selection, and delegation rules belong to the runtime's
`AGENTS.md`, not to each project bootstrap, role, or skill.

The runtime's `AGENTS.md` explicitly loads `instructions/base.md` and
`instructions/git.md` before work; no editor-specific activation metadata is
needed. It then asks the agent to list `$DX_HOME/agents/*.md` and
`$DX_HOME/skills/*/SKILL.md`, inspect `name` and `description` metadata, and
read the selected role or workflow before applying it. Directory contents are
the authoritative list, not a catalog in this guide.

Shared sources live under `.devcontainer/src/dx/runtime/` in `dx` and are
installed by the Feature. Project-specific roles and skills remain additive
under `.agents/agents/` and `.agents/skills/` in the consumer. These are
explicit bootstrap conventions, not universally discovered client paths.
Do not copy shared content, convert its links, generate provider-specific
files, or add per-client adapters or user-profile symlinks.

Neither `DX_HOME` nor these files guarantees a native role picker, automatic
instruction or skill loading, or subagent support. If the client does not read
the root `AGENTS.md`, attach it explicitly through the client's context or
initial request before starting work. For example:

```text
Read the project's AGENTS.md provided in context. Resolve DX_HOME from the
environment (default /opt/dx when absent), read its AGENTS.md and referenced
rules, then list roles and skills and load the resources relevant to this task.
```

Instructions are guidance, not a security enforcement boundary; use execution
permissions and isolation for enforcement.

`.agents/mcp.json` is reserved for a future MCP configuration standard. Do not
add one until that contract is documented in `dx`.

## Runtime state that never belongs in `dx` or in your repository

Tokens, `gh` auth state, and generated MCP configuration are runtime state, not
the DX baseline. DX does not configure or store `gh` state. The official GitHub
MCP server's local stdio OAuth flow keeps its token in memory only, so no MCP
token file or workspace state directory is required. DX uses OAuth as its
single authentication mode.
