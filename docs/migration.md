# Integrating an existing repository

Use this walkthrough to add DX to a repository while preserving its application
configuration, development services and project rules. The complete configuration
examples are in [consumer.md](consumer.md); this guide covers their integration
and verification.

## Prerequisites

Work on a dedicated branch with a known Git status. Identify the project's
required tools, Task contracts, CI jobs, Renovate rules and AI resources before
changing configuration. Preserve business settings, forwarded ports, mounts,
environment requirements and project-specific agents and skills.

Choose a published DX Feature version and existing Git references for the
reusable workflows, Remote Taskfile and Renovate preset. The OCI version and
Git refs are independent: publishing the Feature does not create a Git tag or
GitHub release. Replace `<released-tag>` in the consumer examples with an
existing Git tag; do not infer it from the Feature's version.

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
   provides every project tool. The Feature installs the runtime at `/opt/dx`
   and sets `DX_HOME` through `containerEnv`; rebuild to apply it.
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
   `TASK_REMOTE_TRUSTED_HOSTS=github.com`; additional project dependencies
   must be available on the runner. It executes the selected task on that
   runner, not inside the consumer Dev Container.
4. **GitHub workflows and Renovate**: integrate calls to the reusable validate
   and maintenance workflows without dropping application jobs, triggers or
   required permissions. Extend the DX Renovate preset alongside the project's
   rules. Use existing Git refs in all three configurations; consult
   [consumer.md](consumer.md) for the workflow, include and preset syntax.
5. **AI resources**: add the client-neutral root `AGENTS.md` bootstrap from
   [consumer.md](consumer.md), preserving project-specific rules. It resolves
   `DX_HOME` and loads the runtime guide and shared rules explicitly. Keep
   project agents in `.agents/agents/` and skills in `.agents/skills/`; the
   runtime loads these alongside shared resources by metadata. The Feature's
   VS Code settings discover project agents; they do not configure other
   clients or the checkout-specific runtime path. If the client does not load
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

## Verify the integration

After rebuilding the Dev Container, check the installed tools and runtime:

```sh
printf 'DX_HOME=%s\n' "$DX_HOME"
test -f "$DX_HOME/AGENTS.md"
task --version
task --list
task validate
```

The Feature default is `/opt/dx`; an explicit live-source override uses a
different runtime. With the optional shared Taskfile include, run
`task dx:doctor` to check runtime presence offline. It does not check
authentication. Run the project's `task test` and `task lint` when defined,
then verify CI with the selected Git refs and project dependencies.

In an AI session, check that the root bootstrap loads shared rules and selects
the relevant project resources. Test MCP separately if configured; runtime
presence does not prove client discovery or authentication.

Review the diff for preserved application settings and accidental secrets
before requesting approval to commit or push. To test DX source changes
directly, use [dogfood.md](dogfood.md). Installed runtime updates require a
Feature version update and a container rebuild.
