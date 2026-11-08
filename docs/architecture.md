# Architecture

`Gildraen/dx` provides the shared development environment, AI runtime, MCP
launcher, Task helpers, and reusable CI workflows used by consumer repositories.
This document describes their integration; the
[component reference](decoupage.md) lists responsibilities and interfaces.

## The four categories

| Category | Delivery | Resources |
| --- | --- | --- |
| Referenceable | Consumer selects a Git source and ref | Reusable workflows, Remote Taskfile |
| Installable | Dev Container Feature installs a runtime snapshot | Tools, AI resources, MCP launcher, Task helpers |
| Local bootstrap | Files in the consumer repository configure integration | `devcontainer.json`, `AGENTS.md`, `Taskfile.yml`, workflow callers |
| Project-specific | Owned by the consumer | Business logic, services, ports, project commands, agents and skills |

The Feature is distributed through OCI at `ghcr.io/gildraen/dx/dx`. Workflows
and the Remote Taskfile are resolved through Git references.
These references are selected independently of the Feature version.

## What lives where

| Concern | Source | Installed location or consumer interface |
| --- | --- | --- |
| Environment | [Feature manifest](../.devcontainer/src/dx/devcontainer-feature.json), [installer](../.devcontainer/src/dx/install.sh) | Feature dependencies, environment variables, mount, VS Code settings |
| Runtime entry point | [runtime AGENTS.md](../.devcontainer/src/dx/runtime/AGENTS.md) | `/opt/dx/AGENTS.md` |
| Shared instructions | `.devcontainer/src/dx/runtime/instructions/` | `/opt/dx/instructions/` |
| Shared roles (`*.agent.md`) | `.devcontainer/src/dx/runtime/agents/` | `/opt/dx/agents/` |
| Shared skills (`*/SKILL.md`) | `.devcontainer/src/dx/runtime/skills/` | `/opt/dx/skills/` |
| MCP launcher | [dx-mcp](../.devcontainer/src/dx/runtime/bin/dx-mcp) | `/opt/dx/bin/dx-mcp`, wrapper in `/usr/local/bin/dx-mcp` |
| Task helpers | [base.yml](../.devcontainer/src/dx/runtime/taskfiles/base.yml) | Remote Taskfile; also installed in `/opt/dx/taskfiles/` |
| CI | `.github/workflows/reusable-*.yml` | GitHub reusable workflow calls |
| Project roles and skills | Consumer `.agents/agents/*.agent.md`, `.agents/skills/*/SKILL.md` | Explicit loading; VS Code picker for project agents |

## Runtime: `DX_HOME`

The installer copies the packaged runtime to `/opt/dx`. The Feature declares
`DX_HOME=/opt/dx` through `containerEnv`:

```text
/opt/dx/
├── AGENTS.md
├── agents/
├── bin/
├── instructions/
├── skills/
└── taskfiles/
```

The consumer's root `AGENTS.md` resolves `DX_HOME` from the process environment,
using `/opt/dx` when absent, and loads the runtime entry point. See
[consumer.md](consumer.md) for the local bootstrap files.

The runtime guide loads `instructions/base.md` and `instructions/git.md`
before work begins. It directs the agent to inspect shared and project role
and skill metadata, then load the relevant resources in full. Roles use the
`.agent.md` suffix; skills use a directory containing `SKILL.md`. A directly
selected skill also loads its owning role.

The [instruction hierarchy](../.devcontainer/src/dx/runtime/AGENTS.md#instruction-hierarchy)
assigns cross-role rules to the runtime guide and shared instructions, workflow
selection and composition to roles, and bounded procedures and checks to skills.
The [delegation policy](../.devcontainer/src/dx/runtime/AGENTS.md#delegate-focused-work)
requires scoped assignments, explicit edit authorization, disjoint ownership
for concurrent writers, and integration and validation by the main agent.
Clients without subagent support apply the selected role and skills locally
and report that limitation.

Project-specific resources have canonical locations under `.agents/agents/`
and `.agents/skills/` at the repository root. Shared and project resources are
additive. The root bootstrap must load the runtime guide for this routing to
apply; file availability alone does not guarantee automatic loading.

### Client integration

The Feature configures VS Code's `chat.agentFilesLocations` for
`.agents/agents` and declares its chat client settings in the manifest.
This checkout additionally exposes `.devcontainer/src/dx/runtime/agents`
through its [Dev Container configuration](../.devcontainer/devcontainer.json).
That source path is specific to development of DX, not a consumer location.

The Markdown runtime does not require a particular client, model, or editor.
Native role discovery and subagent support depend on the client. The explicit
`AGENTS.md` loading procedure is separate from VS Code picker configuration.
Instructions are not a security enforcement boundary: permissions and
isolation belong to the execution environment. Secrets and authentication
state must stay out of versioned files.

### Installed and live sources

An installed runtime is a Feature snapshot. Updating it requires selecting the
Feature version and rebuilding the container. This repository instead sets
`remoteEnv.DX_HOME` to
`${containerWorkspaceFolder}/.devcontainer/src/dx/runtime`; its root
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

The installed wrapper resolves `DX_HOME`, then executes `bin/dx-mcp` from that
runtime. Without an explicit value, it checks the local dogfood runtime under
`.devcontainer/.dx` before falling back to `/opt/dx`. DX provides the launcher,
not a custom MCP server or token store.

The Feature sets `GH_CONFIG_DIR=/var/lib/dx/devcontainer/.gh` and bind-mounts
the consumer's `.devcontainer` directory at `/var/lib/dx/devcontainer`.
GitHub CLI authentication state therefore persists in the local `.gh`
directory and must not be committed.

## Task and CI

The shared Taskfile exposes `doctor` and `mcp:github`. The consumer defines its
own `validate`, `test`, and `lint` contracts. `doctor` reports the resolved
runtime directory and fails when it is absent; `mcp:github` invokes the launcher.

Reusable workflows operate on the caller's checkout: validate installs Task
`3.53.1` and runs the selected task; devcontainer-test runs `task test` inside
the caller's container; maintenance checks selected Markdown paths with lychee.
Feature-test invokes the DX-specific Feature test script. Their source paths
and inputs are listed in [decoupage.md](decoupage.md).

The [release workflow](../.github/workflows/release.yml) publishes only the
Feature through the Dev Containers action. Its manifest version identifies the
OCI artifact; the CLI manages version aliases in the repository namespace.
Repository tagging is disabled. Publishing the Feature does not create Git refs for workflows,
or Taskfiles. DX does not run a file-propagation or drift-checking
engine for consumers.
