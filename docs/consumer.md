# Consuming `dx`

This guide covers installing and configuring `dx` in a repository. For
working on `dx` itself using a real project as a testbed, see
[dogfood.md](dogfood.md).

## 1. Dev Container Feature

For integration testing, use the local Feature checkout (see
[dogfood.md](dogfood.md) to create `.devcontainer/.dx`). Each component uses a
SemVer tag for Renovate's update stream and a commit SHA as the immutable
checkout ref. The example pair selects candidate `v0.1.0-rc.1`, a prerelease,
not a stable release:

```jsonc
// .devcontainer/devcontainer.json
{
  "name": "my-project",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu-24.04",
  "features": {
    "./.dx/.devcontainer/src/dx": {
      "agentsVersion": "v0.1.0-rc.1",
      "agentsCommit": "a448037a8b96b2269ac1b46f0ff2018738083c1e",
      "toolsVersion": "v0.1.0-rc.1",
      "toolsCommit": "6630f37ffdc3a8c51af0f4795145a4743a61584b"
    }
  }
}
```

For an installed release, replace the local Feature key with
`ghcr.io/gildraen/dx/dx:<released-version>` and select a published version
whose manifest exposes the component version and commit options. A previously
published Feature does not acquire these options automatically.

Only add other Features or packages for project-specific requirements
(Docker-outside-of-Docker, project language runtimes, service CLIs, …). The DX
Feature does not provide those tools.

The [Feature manifest](../.devcontainer/src/dx/devcontainer-feature.json)
declares Node.js LTS, GitHub CLI, Go Task 3.53.1, Git, `jq`, ripgrep and
`libatomic1`. Check the manifest of the selected release before relying on a
tool; requirements not included there remain project-specific.

The Feature fetches each tag and verifies it resolves to the matching commit
SHA, then checks out that SHA into `/opt/dx/components/agents` and
`/opt/dx/components/tools`. The version and commit options are independent per
component but must be updated as a pair. It sets `DX_AGENTS_HOME`
and `DX_TOOLS_HOME` to those locations, retaining `DX_HOME=/opt/dx` and
compatibility symlinks for `AGENTS.md`, `instructions/`, `agents/`, `skills/`,
`bin/` and `taskfiles/`. Shared roles are under
`/opt/dx/components/agents/agents/`; `/opt/dx/agents` links to that directory,
not to the component root.
No copy of either component is versioned in the Feature source. The installed
checkouts are snapshots; change the relevant tag/SHA pair and rebuild to update one
without changing the Feature version. For live sources, use [dogfood.md](dogfood.md).
The launcher runs GitHub's pinned official MCP image through Docker and does
not manage a GitHub token. A project that enables MCP must provide Docker
access and configure its MCP client separately. The launcher has no
per-consumer image setting. DX does not
authenticate the GitHub CLI automatically.

### Git credentials and GitHub CLI state

Git uses native [VS Code Dev Containers credential sharing](https://code.visualstudio.com/remote/advancedcontainers/sharing-git-credentials):
the extension copies the host's `.gitconfig`, reuses its credential helper for
HTTPS, and forwards a running host SSH agent. Configure Git identity and
credentials on the host. DX does not set `GIT_SSH_COMMAND`, generate SSH keys,
or authenticate Git automatically.

The Feature sets `containerEnv.GH_CONFIG_DIR=/var/lib/dx/devcontainer/.gh`
and declares this bind mount:

```json
{
  "source": "${localWorkspaceFolder}/.devcontainer",
  "target": "/var/lib/dx/devcontainer",
  "type": "bind"
}
```

The host workspace root must contain `.devcontainer`. Consumers with Dev
Container configurations elsewhere must adapt the mounts in their own
configuration; the source is not resolved relative to `devcontainer.json`.
`gh` creates `.gh` when it writes configuration.

Files live directly in the host's `.devcontainer/.gh` and survive container
rebuilds and workspace moves if those files are retained. Existing host state
at that location is reused directly. Ownership and permissions come from the
host filesystem. This is `gh` configuration and may contain tokens; it is not
SSH private-key storage. Consumers must ensure the remote user
can write to the mounted directory. To use other storage, override
`GH_CONFIG_DIR` through `remoteEnv` and manage that storage in the consumer.

For GitHub API access through `gh`, run `gh auth login` only when neither
`GH_TOKEN` nor `GITHUB_TOKEN` nor existing authentication state is available.
This authentication is distinct from Git/SSH credentials. For GitHub HTTPS
only, if no credential helper is configured and you explicitly want Git to
reuse `gh` authentication, run `gh auth setup-git`. DX does not run it or
overwrite an existing helper automatically.

Without a keyring, `gh` may store tokens in plaintext: treat this directory
as secret storage, never commit its state or bake it into an image. The
consumer must exclude it from Git, either with a parent ignore rule or a
consumer-provided `.devcontainer/.gh/.gitignore` containing:

```gitignore
*
!.gitignore
```

DX does not create this ignore file. Any alternative workspace storage must
also be ignored by Git.

## 2. Reusable GitHub workflows

```yaml
# .github/workflows/validate.yml
name: validate
on:
  pull_request:
jobs:
  validate:
    uses: Gildraen/ci-workflows/.github/workflows/reusable-validate.yml@b8cc1c66c153e49887f0c63baa4a1aa238998b10 # v0.1.0-rc.1
```

The reusable workflow runs `task validate` (configurable via the `task-name`
input) in your repository. Your `Taskfile.yml` defines what `validate` (and
`test`, `lint`, …) means for your stack — the workflow only enforces the contract,
not the implementation. It preserves `TASK_REMOTE_TRUSTED_HOSTS=github.com`
for includes hosted on `github.com`, avoiding an interactive trust prompt for
those URLs without enabling global `--yes` behavior. The Remote Taskfile
example below uses that host.

Same pattern for maintenance / link-checking:
`Gildraen/ci-workflows/.github/workflows/reusable-maintenance.yml@b8cc1c66c153e49887f0c63baa4a1aa238998b10 # v0.1.0-rc.1`.
For tests in the consumer container, use
`Gildraen/ci-workflows/.github/workflows/reusable-devcontainer-test.yml@b8cc1c66c153e49887f0c63baa4a1aa238998b10 # v0.1.0-rc.1`;
the container must provide `task test`. DX's `reusable-feature-test.yml` is
local to the Feature repository, not part of these portable workflows.

DX also exposes three compatibility wrappers at
`Gildraen/dx/.github/workflows/reusable-{validate,devcontainer-test,maintenance}.yml`.
They delegate to the external workflows at the pinned SHA above and retain the
version tag in a comment for Renovate. They forward their inputs without copying implementations. Callers using floating DX references
can retain these paths.

## 3. Remote Taskfile (optional shared helpers)

```yaml
# Taskfile.yml
includes:
  dx: https://github.com/Gildraen/dx-tools/raw/6630f37ffdc3a8c51af0f4795145a4743a61584b/taskfiles/base.yml # v0.1.0-rc.1
```

Gives you `task dx:doctor` and `task dx:mcp:github`.
`task dx:doctor` checks `DX_TOOLS_HOME` offline, with a `DX_HOME` compatibility
fallback, not authentication.
Your own `validate`/`test`/`lint` tasks stay in your Taskfile.

Remote Taskfiles require Go Task 3.53.1 or newer. The DX Feature and reusable
validation workflow both provide a compatible release.

The reusable validation workflow installs a compatible Task release on its GitHub
Actions runner before executing `task validate`. Its availability in CI does
not mean that the local devcontainer already provides it.

The URL pins the commit SHA. Its trailing version tag comment is Renovate's
update stream. Use the direct HTTP URL above with Task 3.53.1.

For a manual invocation, either accept Task's host trust prompt or restrict
non-interactive trust to `github.com`:

```sh
TASK_REMOTE_TRUSTED_HOSTS=github.com task dx:doctor
```

The reusable validation workflow already sets this environment value, so the
same include works locally and in CI. Do not use global `--yes`. Trust must
be set in the environment invoking Task.

## 4. Agents and skills

Keep the root `AGENTS.md` small: a bootstrap plus genuinely project-specific
rules. The runtime does not require a particular AI client, model, or editor.
Use this bootstrap in the consumer:

````markdown
# Project agent instructions

Before any work, resolve DX_AGENTS_HOME from the process environment; use
/opt/dx/components/agents only when DX_AGENTS_HOME is absent. Read its AGENTS.md and
follow the shared guidance.

## Project-specific rules
...
````

Common loading, selection, and delegation rules belong to dx-agents'
`AGENTS.md`, not to each project bootstrap, role, or skill.

The shared `AGENTS.md` explicitly loads `instructions/base.md` and
`instructions/git.md` before work; no editor-specific activation metadata is
needed. It then asks the agent to list `$DX_AGENTS_HOME/agents/*.agent.md` and
`$DX_AGENTS_HOME/skills/*/SKILL.md`, inspect `name` and `description` metadata, and
read the selected role or workflow before applying it. Directory contents are
the authoritative list, not a catalog in this guide.

Shared sources live at the root of `Gildraen/dx-agents` and can be used
independently of the Feature, Docker, MCP and the tools component. For local
checkouts at the candidate commit SHAs, from the consumer root:

```sh
git init .devcontainer/components/agents
git -C .devcontainer/components/agents remote add origin https://github.com/Gildraen/dx-agents.git
git -C .devcontainer/components/agents fetch --depth=1 origin a448037a8b96b2269ac1b46f0ff2018738083c1e
git -C .devcontainer/components/agents checkout --detach FETCH_HEAD
export DX_AGENTS_HOME="$PWD/.devcontainer/components/agents"
```

This example creates a separate Git checkout, not a copy owned by the
consumer. Keep it out of the consumer's tracked files, or declare it as a
pinned submodule. Tools can likewise be checked out independently:

```sh
git init .devcontainer/components/tools
git -C .devcontainer/components/tools remote add origin https://github.com/Gildraen/dx-tools.git
git -C .devcontainer/components/tools fetch --depth=1 origin 6630f37ffdc3a8c51af0f4795145a4743a61584b
git -C .devcontainer/components/tools checkout --detach FETCH_HEAD
export DX_TOOLS_HOME="$PWD/.devcontainer/components/tools"
export PATH="$DX_TOOLS_HOME/bin:$PATH"
```

The example tracks tag `v0.1.0-rc.1` with those exact commit SHAs. Renovate
updates the version and commit options together. For a submodule, the parent
repository records the pinned commit as a gitlink; `.gitmodules` does not carry
the version tag.

Project-specific roles and skills remain additive
under `.agents/agents/` and `.agents/skills/` in the consumer. These are
the sole canonical project locations. Do not keep duplicate project resources
in client-specific directories. After the consumer's root `AGENTS.md` loads
`$DX_AGENTS_HOME/AGENTS.md`, that guide explicitly
inspects both project paths and selects relevant resources by metadata. This
is the client-neutral loading procedure. Native discovery uses local paths:
`$DX_AGENTS_HOME/agents` for roles and `$DX_AGENTS_HOME/skills` for skills.
For the separate checkout above these are `.devcontainer/components/agents/agents`
and `.devcontainer/components/agents/skills`; for installed resources they are
`/opt/dx/components/agents/agents` and `/opt/dx/components/agents/skills`. VS Code custom agent
directories require `.agent.md` files. Configure discovery using the client's
supported mechanisms; a GitHub URL is not a native agent or skill directory.
The Feature does not install resources into Copilot user directories.

Neither `DX_AGENTS_HOME` nor these files guarantees a native role
picker, automatic instruction or skill loading, or subagent support. If the
client does not read the root `AGENTS.md`, attach it explicitly through the
context or initial request before starting work. For example:

```text
Read the project's AGENTS.md provided in context. Resolve DX_AGENTS_HOME from
the environment (default /opt/dx/components/agents when absent), read its AGENTS.md and
referenced rules, then list `$DX_AGENTS_HOME/agents/*.agent.md`,
`$DX_AGENTS_HOME/skills/*/SKILL.md`,
`.agents/agents/*.agent.md`, and `.agents/skills/*/SKILL.md`. Select relevant
resources from their metadata and load them before proceeding.
```

Instructions are guidance, not a security enforcement boundary; use execution
permissions and isolation for enforcement. The runtime requests delegation,
but a managed subagent tool and its permissions depend on the client. When
subagents are unavailable, apply the selected role in the current agent and
report that fallback.
Cross-repository use consists of loading these local shared files explicitly
and giving the selected rules, role, scope and permissions to the client's
subagent tool; it does not invoke an agent directly from a remote URL.

## 5. GitHub MCP client

Configure your MCP client's stdio server command as `dx-mcp` with the argument
`github`. The launcher requires a Docker CLI and accessible daemon, starts the
official GitHub MCP server with OAuth, and binds its callback port to
`127.0.0.1:8085`. Ensure this port is available and the authentication flow can
reach it in your environment. MCP client configuration belongs to the project
or client, not to the shared agent bootstrap.

GitHub MCP OAuth authentication is separate from Git/SSH and `gh`
authentication. The launcher does not forward `GH_TOKEN` or `GITHUB_TOKEN` to
the server. Configure application-level client access separately from runtime
resource loading through `DX_AGENTS_HOME`.

## 6. Renovate preset

DX uses the shared preset reference
`github>Gildraen/renovate-config#v0.1.0-rc.1`
in `extends`, fixed to the candidate version tag independently of the Feature and
component refs.

## Runtime state that never belongs in `dx` or in your repository

Tokens, `gh` auth state, and generated MCP configuration are runtime state,
never versioned DX or consumer content. DX provides a default `gh`
configuration location backed by the host's `.devcontainer` bind mount, not
credentials. The consumer owns its storage permissions and Git ignore rules.
Treat generated machine-specific client settings as potentially secret;
inspect their handling locally and keep authentication state out of Git and
container images.
