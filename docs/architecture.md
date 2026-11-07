# Architecture

`Gildraen/dx` is the source of truth for the DX shared by Gildraen
repositories. It is **consumed by reference**, not copied.

```
                         Gildraen/dx
                              │
             ┌────────────────┼────────────────┐
             │                │                │
      Dev Container      reusable CI      Renovate preset
        Feature (GHCR)    workflows        (default.json)
             │                │                │
             └────────────────┼────────────────┘
                              │
                         published releases
                              │
               ┌──────────────┼──────────────┐
               ▼              ▼              ▼
              Niki          infra        local-llm
```

## The four categories

Every DX resource falls into one of these categories. Classifying a resource
this way is the main design tool used throughout this repository.

1. **Référençable** — the consumer points directly at the shared source
   (reusable GitHub workflows, a Remote Taskfile, a Renovate preset). Never
   copied.
2. **Installable** — packaged and installed as part of the dev environment,
  mainly through the `dx` Dev Container Feature (`.devcontainer/src/dx/`). Covers the DX
   runtime (agents, MCP launchers, task helpers).
3. **Bootstrap local obligatoire** — a handful of tools still require a file
   physically present in the consumer repository (`devcontainer.json`,
   `AGENTS.md`, `Taskfile.yml`). These stay tiny and only reference the
   shared system; they never duplicate logic.
4. **Spécifique au projet** — business logic, ports, Docker specifics,
   project test commands, project-specific agent rules. These never move
   into `dx`.

## What lives where

| Concern | Category | Where |
|---|---|---|
| Shared tool baseline | Installable | DX Feature manifest |
| Shared entry point | Installable | `.devcontainer/src/dx/runtime/AGENTS.md` -> `/opt/dx/AGENTS.md` |
| Shared instructions (`base.md`, `git.md`) | Installable | `.devcontainer/src/dx/runtime/instructions/` -> `/opt/dx/instructions/` |
| Shared roles (one `.md` file per role; the directory listing is authoritative, not this table) | Installable | `.devcontainer/src/dx/runtime/agents/` -> `/opt/dx/agents/` |
| Shared skills (one directory per skill with a `SKILL.md`; the directory listing is authoritative, not this table) | Installable | `.devcontainer/src/dx/runtime/skills/` -> `/opt/dx/skills/` |
| Shared Task helpers | Référençable (Remote Taskfile) | `.devcontainer/src/dx/runtime/taskfiles/base.yml` |
| CI contracts (`validate`, `test`, `lint`) | Référençable (reusable workflow) | `.github/workflows/reusable-*.yml` |
| Renovate rules | Référençable (preset) | `default.json` |
| `devcontainer.json`, `AGENTS.md`, `Taskfile.yml` | Bootstrap local obligatoire | short files in each consumer repo |
| Explicit resource loading | Bootstrap local obligatoire | project `AGENTS.md` -> runtime `AGENTS.md` -> rules, selected roles and skills |
| Project agents (canonical source) | Spécifique au projet | `.agents/agents/` in each consumer repository |
| Project skills | Spécifique au projet | `.agents/skills/` in each consumer repository |
| Future MCP config | Bootstrap local obligatoire | `.agents/mcp.json` once the contract exists |
| Business logic, service specifics | Spécifique au projet | stays in each repository |

## Runtime: `DX_HOME`

The Feature installs the shared runtime to a stable path:

```
DX_HOME=/opt/dx
/opt/dx/
├── AGENTS.md
├── agents/
├── bin/
├── instructions/
├── skills/
└── taskfiles/
```

The runtime contains an `AGENTS.md` entry point, shared instructions, on-demand
roles, shared skills, Task helpers, and a small `dx-mcp` launcher. Its Markdown
resources are independent of any AI client, model, or editor. GitHub MCP itself is provided by
GitHub's official container image; DX does not install an npm package or
manage a token store.

The Feature copies the versioned runtime to `/opt/dx` and declares
`DX_HOME=/opt/dx` through `containerEnv`. It also contributes the VS Code
setting `chat.agentFilesLocations` for `.agents/agents/`, so canonical project
agents appear in the VS Code picker.
For native Copilot discovery, it also symlinks shared runtime agents and skills
from `DX_HOME` into the remote container user's `~/.copilot/agents/` and
`~/.copilot/skills/`. These links point back to the canonical runtime; they do
not copy resources into the workspace or host home, and conflicting existing
entries are preserved.
The project's small `AGENTS.md` asks the agent to resolve `DX_HOME` from the
process environment (default `/opt/dx` when absent) and read its `AGENTS.md`.
That entry point explicitly loads `instructions/base.md` and
`instructions/git.md` before any work. These rules apply through explicit
loading, not editor-specific activation metadata. Missing rules must be
reported rather than silently skipped.

That runtime guide also directs the agent to inspect project roles in
`.agents/agents/*.md` and project skills in `.agents/skills/*/SKILL.md`.
The Feature delivers this routing instruction as part of the installed
runtime; the consumer's root `AGENTS.md` must load it. This is explicit prompt
loading for all clients; the Feature additionally configures VS Code's picker
for project agents. The agent location setting is supported but editor-specific,
so independent Copilot clients do not inherit it.

To choose a role, list `agents/*.md`, inspect `name` and `description`, then
read the selected file in full. For workflows, list `skills/*/SKILL.md` and
use the same metadata-driven selection. Directory contents are authoritative;
no central role or skill list is required. Each skill links to its owning
role, and the role links back to its workflows. Read that role even when a
skill is requested directly. The role selects and composes the skills needed
for the task, deciding their order and integration without loading them all.

Responsibilities follow the instruction hierarchy: the runtime guide and
shared instructions own cross-role execution rules; roles own workflow
selection, composition, and shared domain rules; skills own bounded procedures,
specific checks, and results. Child resources inherit these rules rather than
repeating them. See the
[runtime hierarchy](../.devcontainer/src/dx/runtime/AGENTS.md#instruction-hierarchy)
for the canonical contract.

Delegate focused work with an explicit scope, applicable rules, selected role
and skills, expected result, and edit authorization. Give concurrent writers
disjoint file ownership. Dependent steps run sequentially; independent bounded
assignments may run in parallel. If the client cannot run subagents, apply the
selected role and skills in the current agent and report that fallback. The
main agent remains responsible for integration and validation. See the
[delegation policy](../.devcontainer/src/dx/runtime/AGENTS.md#delegate-focused-work)
for the complete rules.

DX resources and project resources are additive. Project customizations stay
in `.agents/agents/*.md` and `.agents/skills/*/SKILL.md`; the bootstrap asks the
agent to list them and load relevant resources explicitly, as described in
[consumer.md](consumer.md). These are the sole canonical project locations;
do not keep duplicate project resources in client-specific directories. The
paths are not universal native discovery locations, so the runtime bootstrap
loads them explicitly. The Feature contributes VS Code picker discovery for
project agents and native Copilot user locations for shared resources. The
Copilot profile entries are symlinks to the canonical runtime, not copied
resource files.
`.agents/mcp.json` is reserved for a later MCP configuration contract and
should not be introduced before that contract is documented here.

For clients other than VS Code, file availability and `DX_HOME` do not guarantee
a native role picker or automatic loading; the explicit `AGENTS.md` bootstrap
is the loading contract. The Feature adds `.agents/agents/` to the VS Code
picker only. Subagent support also depends on the client. Instructions guide
the agent; they are not a security enforcement boundary. Permissions and
isolation must be enforced by the execution environment.

Stable consumers use the installed snapshot; runtime changes require updating
the Feature release and rebuilding their container. Dogfood explicitly sets
`remoteEnv.DX_HOME` to the live worktree runtime and reads it through the same
bootstrap, without discovery settings (see [dogfood.md](dogfood.md)). This
repository sets `remoteEnv.DX_HOME` to
`${containerWorkspaceFolder}/.devcontainer/src/dx/runtime`; its root
[AGENTS.md](../AGENTS.md) links directly to the local runtime entry point.

## Shared tool baseline

DX is a common base for Gildraen projects as well as a shared reference source.
A released Feature may therefore guarantee a deliberately small set of
system tools. Admission requires one of these conditions:

- the tool is required by a shared DX contract; or
- it is expected to be used durably by most Gildraen repositories.

Convenience alone is not sufficient. Project language runtimes, service CLIs,
and specialist utilities remain consumer-specific.

The common baseline is Node.js LTS, GitHub CLI, Go Task, `jq`, and ripgrep
(`rg`). The Feature manifest is the source of truth for this baseline. DX owns
the guarantee declaratively by depending on the
official `node` and `github-cli` Features, the dedicated `go-task` Feature, and
the `apt-get-packages` Feature for `jq` and `ripgrep`; it does not duplicate
their installation logic. The package Feature also installs `git`, a technical
prerequisite of the selected Task Feature on a minimal image. Node.js and GitHub
CLI are part of the shared agent/dev workflow inherited from the pre-DX
consumer baseline. Go Task supports the shared `task validate` contract and
Remote Taskfiles. `jq` and `rg` are portable shell primitives likely to be
reused across repositories. Consumers should rely only on tools declared by
the Feature release they have selected; tools outside that contract remain
consumer-specific.

## What `dx` intentionally does *not* do

- No custom CLI, framework, daemon, or file-propagation engine.
- No list of consumer repositories (`targetRepos`) and no drift/coherence
  checker comparing canonical files against copies.
- No unbounded tool bundle: a system tool enters the baseline only under the
  shared-tool policy above.
- Ollama and Docker-outside-of-Docker are **not** part of the common
  baseline: they are only relevant to specific projects and are configured
  there, not in `dx`.

## Dogfood loop

```
Gildraen/dx feature branch
          │
          ▼
      git worktree
          │
          ▼
  project/.devcontainer/.dx
          │
          ▼
 real project used as testbed
          │
          ▼
       release
```

See [dogfood.md](dogfood.md) for the exact procedure.
