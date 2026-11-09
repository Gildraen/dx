# Integrating an existing repository

Use this walkthrough to add DX to a repository while preserving its application
configuration, development services and project rules. The complete configuration
examples are in [consumer.md](consumer.md); this guide covers their integration
and verification.

## Prerequisites

Work on a dedicated branch with a known Git status. Identify the project's
required tools, Task contracts, CI jobs and AI resources before
changing configuration. Preserve business settings, forwarded ports, mounts,
environment requirements and project-specific agents and skills.

Choose a DX Feature whose manifest supports `agentsRef` and `toolsRef`, plus
version tags in `Gildraen/dx-agents`, `Gildraen/dx-tools` and
`Gildraen/ci-workflows`. The candidate component and preset version is
`v0.1.0-rc.1`, a prerelease, not a stable release. The local Feature test and fixed component
examples are in [consumer.md](consumer.md); they do not claim that an older
published Feature implements the new options. OCI versions and Git refs are
independent: publishing the Feature does not create a Git tag or GitHub release.
Existing DX Git tags remain valid for their original contents.

Dev Container use requires a compatible client and container engine. Docker
access for GitHub MCP is a separate project dependency. Remote Taskfiles
require Go Task 3.53.1 or newer. The
[Feature manifest](../.devcontainer/src/dx/devcontainer-feature.json) declares
the common tools; check the selected release for compatibility with the
project's requirements.

## Configure the repository

1. **Dev Container**: add the DX Feature to the existing `features` object using
   the [consumer example](consumer.md). Keep project-specific language runtimes,
   service CLIs and Docker access where required. Reconcile overlapping tool
   dependencies with the selected Feature manifest rather than assuming DX
   provides every project tool. The Feature installs IA at `/opt/dx/components/agents`
   and tools at `/opt/dx/components/tools`, setting `DX_AGENTS_HOME` and `DX_TOOLS_HOME`.
   `DX_HOME=/opt/dx` and compatibility symlinks retain the shared entry point
   and helper paths: `AGENTS.md`, `instructions/`, `agents/`, `skills/`, `bin/`
   and `taskfiles/`. `/opt/dx/agents` links to `components/agents/agents`, not
   to the component home. Rebuild to
   apply the selected refs.
2. **Authentication and storage**: keep Git identity and credentials on the
   host for native VS Code Dev Containers sharing. Ensure the remote user can
   write to the `.devcontainer` bind mount backing `GH_CONFIG_DIR`. Exclude
   `.devcontainer/.gh` from Git before authenticating. Follow the
   [authentication instructions](consumer.md): use `gh auth login` only when
   no token environment or existing authentication is available; Git/SSH,
   `gh` and MCP OAuth authentication are separate. Without a keyring, `gh`
   may store tokens in plaintext.
3. **Task contracts**: retain the project's `validate`, `test` and `lint`
   implementations and their dependencies. Add the optional Remote Taskfile
   include for `dx:doctor` and `dx:mcp:github` if needed. In CI, the reusable
   validation workflow supplies Task and sets
   `TASK_REMOTE_TRUSTED_HOSTS=github.com` for includes hosted on `github.com`.
   The raw URL in [consumer.md](consumer.md#3-remote-taskfile-optional-shared-helpers)
   uses `https://github.com/Gildraen/dx-tools/raw/v0.1.0-rc.1/taskfiles/base.yml`
   and is covered by that trust value. Task 3.53.1 uses this direct HTTP include.
   Additional project dependencies
   must be available on the runner. It executes the selected task on that
   runner, not inside the consumer Dev Container.
4. **GitHub workflows**: integrate calls to the portable validate,
   devcontainer-test and maintenance workflows in `Gildraen/ci-workflows`
   without dropping application jobs, triggers or required permissions.
   DX's local reusable-feature-test is not a consumer workflow.
   Use fixed version tags for workflows and the Remote
   Taskfile; consult [consumer.md](consumer.md) for the workflow and include syntax.
5. **AI resources**: add the client-neutral root `AGENTS.md` bootstrap from
   [consumer.md](consumer.md), preserving project-specific rules. It resolves
   `DX_AGENTS_HOME` and loads the shared guide and rules explicitly. Keep
   project agents in `.agents/agents/` and skills in `.agents/skills/`; the
   guide loads these alongside shared resources by metadata. Native discovery
   uses local role and skill directories, not GitHub URLs; the independent
   pinned checkout example is in [consumer.md](consumer.md). If the client does not load
   `AGENTS.md`, provide it through context or the initial request. Native
   discovery and managed subagent tools depend on the client; without
   subagents, apply the selected role in the current agent and report the
   fallback.
6. **MCP client**: if needed, configure a stdio server using `dx-mcp github`
   and provide Docker access and an available OAuth callback port. Use the
   [MCP configuration guidance](consumer.md). Application-level client
   configuration is separate from runtime instructions. Generated
   machine-specific settings may contain secrets; keep authentication state
   out of versioned files and container images.
7. **Renovate**: DX uses
   `github>Gildraen/renovate-config#v0.1.0-rc.1`,
   fixed to the candidate version tag independently of the Feature and component refs.

## Verify the integration

After rebuilding the Dev Container, check the installed tools and runtime:

```sh
printf 'DX_HOME=%s\n' "$DX_HOME"
printf 'DX_AGENTS_HOME=%s\n' "$DX_AGENTS_HOME"
printf 'DX_TOOLS_HOME=%s\n' "$DX_TOOLS_HOME"
test -f "$DX_AGENTS_HOME/AGENTS.md"
test -x "$DX_TOOLS_HOME/bin/dx-mcp"
test -f "$DX_TOOLS_HOME/taskfiles/base.yml"
task --version
task --list
task validate
```

The installed defaults are `/opt/dx/components/agents` and `/opt/dx/components/tools`; explicit
live-source overrides select different checkouts. With the optional shared
Taskfile include, run `task dx:doctor` to check tools presence offline. It does not check
authentication. Run the project's `task test` and `task lint` when defined,
then verify CI with the selected Git refs and project dependencies.

In an AI session, check that the root bootstrap loads shared rules and selects
the relevant project resources. Test MCP separately if configured; runtime
presence does not prove client discovery or authentication.

Review the diff for preserved application settings and accidental secrets
before requesting approval to commit or push. To test DX source changes
directly, use [dogfood.md](dogfood.md). Installed component updates require a
new selected Git ref and a container rebuild, not necessarily a new Feature
version.
