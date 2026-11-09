# Architecture

`Gildraen/dx` provides the shared Dev Container Feature and integrates IA
resources from `Gildraen/dx-agents`, tools from `Gildraen/dx-tools`, and portable
CI workflows from `Gildraen/ci-workflows`.
This document describes their integration; the
[component reference](decoupage.md) lists responsibilities and interfaces.

## The four categories

| Category | Delivery | Resources |
| --- | --- | --- |
| Referenceable | Consumer selects a Git source and ref | Reusable workflows, Remote Taskfile |
| Installable | Dev Container Feature acquires independent Git snapshots | Tools, IA resources, MCP launcher, Task helpers |
| Local bootstrap | Files in the consumer repository configure integration | `devcontainer.json`, `AGENTS.md`, `Taskfile.yml`, workflow callers |
| Project-specific | Owned by the consumer | Business logic, services, ports, project commands, agents and skills |

The Feature is distributed through OCI at `ghcr.io/gildraen/dx/dx`. Workflows
and the Remote Taskfile are resolved through Git references.
These references are selected independently of the Feature version.
The Feature's `agentsRef` defaults to
`v0.1.0-rc.1`; `toolsRef` defaults to
`v0.1.0-rc.1`. Each selects the candidate version tag from its component
repository; this is a prerelease, not a stable release. No versioned copy of
either component is packaged in DX. The dogfood submodules record resolved
commits as gitlinks; selecting a tag does not add a version field to `.gitmodules`.

## What lives where

| Concern | Source | Installed location or consumer interface |
| --- | --- | --- |
| Environment | [Feature manifest](../.devcontainer/src/dx/devcontainer-feature.json), [installer](../.devcontainer/src/dx/install.sh) | Feature dependencies, environment variables, mount, VS Code settings |
| IA entry point | [dx-agents AGENTS.md](../.devcontainer/components/agents/AGENTS.md) | `/opt/dx/components/agents/AGENTS.md` |
| Shared instructions | `Gildraen/dx-agents`, `instructions/` | `/opt/dx/components/agents/instructions/` |
| Shared roles (`*.agent.md`) | `Gildraen/dx-agents`, `agents/` | `/opt/dx/components/agents/agents/` |
| Shared skills (`*/SKILL.md`) | `Gildraen/dx-agents`, `skills/` | `/opt/dx/components/agents/skills/` |
| MCP launcher | [dx-mcp](../.devcontainer/components/tools/bin/dx-mcp) | `/opt/dx/components/tools/bin/dx-mcp`, wrapper in `/usr/local/bin/dx-mcp` |
| Task helpers | [base.yml](../.devcontainer/components/tools/taskfiles/base.yml) | Remote Taskfile; also installed in `/opt/dx/components/tools/taskfiles/` |
| Portable CI | `Gildraen/ci-workflows`, `.github/workflows/reusable-*.yml` | GitHub reusable workflow calls |
| Feature CI | [reusable-feature-test.yml](../.github/workflows/reusable-feature-test.yml) | DX-specific Feature tests |
| Project roles and skills | Consumer `.agents/agents/*.agent.md`, `.agents/skills/*/SKILL.md` | Explicit loading; VS Code picker for project agents |

## Component locations

The installer acquires the selected agents and tools refs independently.
The Feature declares `DX_AGENTS_HOME=/opt/dx/components/agents`,
`DX_TOOLS_HOME=/opt/dx/components/tools`, and `DX_HOME=/opt/dx`:

```text
/opt/dx/
	components/
		agents/   # dx-agents: AGENTS.md, instructions/, agents/, skills/
		tools/    # dx-tools: bin/, taskfiles/
	AGENTS.md     -> components/agents/AGENTS.md
	instructions/ -> components/agents/instructions/
	agents/       -> components/agents/agents/
	skills/       -> components/agents/skills/
	bin/          -> components/tools/bin/
	taskfiles/    -> components/tools/taskfiles/
```

`DX_HOME` and the six symlinks preserve the entry point, instruction, role,
skill and tool paths. `/opt/dx/agents` points to the roles directory, not the
component root; the component homes live under `/opt/dx/components` to avoid
colliding with that compatibility path.
The consumer's root `AGENTS.md` resolves `DX_AGENTS_HOME` from the environment,
using `/opt/dx/components/agents` when absent, and loads its entry point. See
[consumer.md](consumer.md) for the local bootstrap files.

The runtime guide loads `instructions/base.md` and `instructions/git.md`
before work begins. It directs the agent to inspect shared and project role
and skill metadata, then load the relevant resources in full. Roles use the
`.agent.md` suffix; skills use a directory containing `SKILL.md`. A directly
selected skill also loads its owning role.

The [instruction hierarchy](../.devcontainer/components/agents/AGENTS.md#instruction-hierarchy)
assigns cross-role rules to the runtime guide and shared instructions, workflow
selection and composition to roles, and bounded procedures and checks to skills.
The [delegation policy](../.devcontainer/components/agents/AGENTS.md#delegate-focused-work)
requires scoped assignments, explicit edit authorization, disjoint ownership
for concurrent writers, and integration and validation by the main agent.
Clients without subagent support apply the selected role and skills locally
and report that limitation.

Project-specific resources have canonical locations under `.agents/agents/`
and `.agents/skills/` at the repository root. Shared and project resources are
additive. The root bootstrap must load the runtime guide for this routing to
apply; file availability alone does not guarantee automatic loading.

### Client integration

Native discovery reads local directories: shared roles are under
`$DX_AGENTS_HOME/agents` and shared skills under `$DX_AGENTS_HOME/skills`.
This checkout uses `.devcontainer/components/agents/agents` and
`.devcontainer/components/agents/skills`. Client-specific discovery
configuration is separate from explicit loading; a remote Git URL is not a
native resource location.

The Markdown runtime does not require a particular client, model, or editor.
Native role discovery and subagent support depend on the client. The explicit
`AGENTS.md` loading procedure is separate from VS Code picker configuration.
Instructions are not a security enforcement boundary: permissions and
isolation belong to the execution environment. Secrets and authentication
state must stay out of versioned files.

### Installed and live sources

Installed components are snapshots of their selected refs. Updating
`agentsRef` or `toolsRef` and rebuilding changes the component without changing
the Feature version. This repository sets `DX_AGENTS_HOME` and `DX_TOOLS_HOME`
to `.devcontainer/components/agents` and `.devcontainer/components/tools`;
`initializeCommand` initializes their pinned Git submodules. Its root
[AGENTS.md](../AGENTS.md) loads that local entry point. The
[dogfood guide](dogfood.md) describes using a live checkout in a consumer.

## Shared tool baseline

The [Feature manifest](../.devcontainer/src/dx/devcontainer-feature.json)
declares the installed baseline through `dependsOn`:

| Dependency Feature | Configuration |
| --- | --- |
| `ghcr.io/devcontainers/features/node:2` | Node.js `lts` |
| `ghcr.io/devcontainers/features/github-cli:1` | GitHub CLI, default options |
| `ghcr.io/devcontainers-extra/features/go-task:1` | Task `3.53.1` |
| `ghcr.io/devcontainers-extra/features/apt-get-packages:1` | `git,jq,ripgrep,libatomic1` |

Consumers rely on the manifest of their selected Feature release for tool
availability. Project language runtimes, service CLIs, and specialist tools
are configured in the consumer environment.

## MCP and authentication

`dx-mcp github [server options...]` runs GitHub's official MCP server image
`ghcr.io/github/github-mcp-server:v1.10.1` through Docker. The launcher uses
interactive standard input and publishes the OAuth callback on
`127.0.0.1:8085`. Docker and an accessible daemon are prerequisites; Docker is
not a dependency of the DX Feature. This checkout declares
Docker-outside-of-Docker and the VS Code MCP server command locally.

The installed wrapper uses `DX_TOOLS_HOME/bin/dx-mcp` when that variable is
set. `DX_HOME/bin/dx-mcp` remains the compatibility interface. DX installs the
wrapper; `dx-tools` owns the launcher, not a custom MCP server or token store.

The Feature sets `GH_CONFIG_DIR=/var/lib/dx/devcontainer/.gh` and bind-mounts
the consumer's `.devcontainer` directory at `/var/lib/dx/devcontainer`.
GitHub CLI authentication state therefore persists in the local `.gh`
directory and must not be committed.

## Task and CI

The shared Taskfile exposes `doctor` and `mcp:github`. The consumer defines its
own `validate`, `test`, and `lint` contracts. `doctor` reports the resolved
tools directory and fails when it is absent; `mcp:github` invokes the launcher.
`doctor` uses `DX_TOOLS_HOME` first, with `DX_HOME` as a compatibility fallback.

Reusable workflows operate on the caller's checkout: validate installs Task
`3.53.1` and runs the selected task; devcontainer-test runs `task test` inside
the caller's container; maintenance checks selected Markdown paths with lychee.
The portable workflows are called from `Gildraen/ci-workflows` at
`v0.1.0-rc.1`. Local Feature-test invokes the
DX-specific Feature test script. Their source paths
and inputs are listed in [decoupage.md](decoupage.md).

DX retains three `reusable-*.yml` compatibility wrappers for validate,
devcontainer-test and maintenance. Each delegates to the corresponding external
workflow at that version tag and forwards its inputs, without a local implementation
copy. These paths serve callers using floating DX references.

Task 3.53.1 uses a direct HTTP URL to select the fixed Taskfile version tag.
The [consumer example](consumer.md#3-remote-taskfile-optional-shared-helpers)
uses `https://github.com/Gildraen/dx-tools/raw/v0.1.0-rc.1/taskfiles/base.yml`,
covered by the validation workflow's
`TASK_REMOTE_TRUSTED_HOSTS=github.com` environment value.

The [release workflow](../.github/workflows/release.yml) publishes only the
Feature through the Dev Containers action. Its manifest version identifies the
OCI artifact; the CLI manages version aliases in the repository namespace.
Repository tagging is disabled. Publishing the Feature does not create Git refs for workflows,
or Taskfiles. DX does not run a file-propagation or drift-checking
engine for consumers.

## Dependency updates

DX extends the Renovate preset
`github>Gildraen/renovate-config#v0.1.0-rc.1`.
This candidate version tag is selected independently of the Feature, IA, tools and
CI refs.
