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
                       versioned releases (SemVer tags)
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
| Shared tool baseline | Installable | DX Feature, when guaranteed by its released version |
| Agent instructions (`base.md`, `git.md`) | Installable | `.devcontainer/src/dx/runtime/agents/` → `$DX_HOME/agents/` |
| Shared Task helpers | Référençable (Remote Taskfile) | `.devcontainer/src/dx/runtime/taskfiles/base.yml` |
| CI contracts (`validate`, `test`, `lint`) | Référençable (reusable workflow) | `.github/workflows/reusable-*.yml` |
| Renovate rules | Référençable (preset) | `default.json` |
| `devcontainer.json`, `AGENTS.md`, `Taskfile.yml` | Bootstrap local obligatoire | short files in each consumer repo |
| Business logic, service specifics | Spécifique au projet | stays in each repository |

## Runtime: `DX_HOME`

The Feature installs the versioned runtime to a stable path:

```
DX_HOME=/opt/dx
/opt/dx/
├── agents/
├── bin/
└── taskfiles/
```

The runtime contains shared agent instructions, Task helpers, and a small
`dx-mcp` launcher. GitHub MCP itself is provided by GitHub's official container
image; DX does not install an npm package or manage a token store.

`DX_HOME` selects the installed agent instructions in stable mode and the live
worktree runtime in dogfood mode (see [dogfood.md](dogfood.md)).

## Shared tool baseline

DX is a common base for Gildraen projects as well as a versioned reference
source. A released Feature may therefore guarantee a deliberately small set of
system tools. Admission requires one of these conditions:

- the tool is required by a shared DX contract; or
- it is expected to be used durably by most Gildraen repositories.

Convenience alone is not sufficient. Project language runtimes, service CLIs,
and specialist utilities remain consumer-specific.

The `1.1.0` baseline is Go Task, `jq`, and ripgrep (`rg`). The DX Feature owns
this guarantee declaratively by depending on the dedicated `go-task` Feature
and the `apt-get-packages` Feature for `jq` and `ripgrep`; it does not duplicate
their installation logic. The package Feature also installs `git`, a technical
prerequisite of the selected Task Feature on a minimal image. Go Task supports
the shared `task validate` contract and Remote Taskfiles. `jq` and `rg` are
portable shell primitives likely to be reused across repositories. The released
`1.0.0` Feature does not install them, so consumers must install what they use
until `1.1.0` is published and adopted.

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
