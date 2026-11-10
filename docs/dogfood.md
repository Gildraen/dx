# Dogfooding a `dx` change in a real project

Dogfood uses a real Git worktree of `Gildraen/dx` inside a consumer project.
The worktree is created by the DX repository, not by the consumer repository,
and `.devcontainer/.dx` is local-only state.

Use a local DX clone, a consumer with a `.devcontainer` directory, Git worktree
support, and Go Task 3.53.1 or newer. Feature tests also require a Docker CLI
and daemon whose host can access the checkout and temporary test paths. The
paths below are examples, not a statement that a particular repository uses DX.

## Create the worktree

For this layout:

```text
~/projects/dx/
~/projects/my-project/
```

create a new branch and worktree from DX's published integration branch
`feat/component-extraction`:

```sh
cd ~/projects/dx
git fetch origin feat/component-extraction
git worktree add -b feature/my-dx-change ../my-project/.devcontainer/.dx origin/feat/component-extraction
git -C ../my-project/.devcontainer/.dx submodule update --init --recursive
```

The command creates `my-project/.devcontainer/.dx` as a linked worktree of `dx` on
`feature/my-dx-change`. Verify the ownership from the worktree itself:

```sh
cd ~/projects/my-project/.devcontainer/.dx
git status
git remote -v
git branch --show-current
```

Changes under `my-project/.devcontainer/.dx` belong to `Gildraen/dx`, not to
the consumer. Exclude the
worktree only in the consumer clone:

```sh
cd ~/projects/my-project
echo '.devcontainer/.dx/' >> .git/info/exclude
git status --short
```

## Use the live DX sources

The DX worktree has pinned submodules at `.devcontainer/components/agents`
and `.devcontainer/components/tools`. Changes inside them belong to
`Gildraen/dx-agents` or `Gildraen/dx-tools`, not to DX; DX tracks their commit
pointers. Its `initializeCommand` runs `git submodule update --init --recursive`.
The candidate component version is `v0.1.0-rc.1`, a prerelease, not a stable
release. To select it, check out the tag in each initialized submodule with
`git checkout --detach v0.1.0-rc.1`; DX records the resolved commits as gitlinks.

From the consumer, select those local components for the current shell:

```sh
cd ~/projects/my-project
export DX_AGENTS_HOME="$PWD/.devcontainer/.dx/.devcontainer/components/agents"
export DX_TOOLS_HOME="$PWD/.devcontainer/.dx/.devcontainer/components/tools"
```

The Feature defaults to installed checkouts at `/opt/dx/components/agents` and
`/opt/dx/components/tools`; these explicit overrides select live sources instead.
The installed `/usr/local/bin/dx-mcp` wrapper uses
`$DX_TOOLS_HOME/bin/dx-mcp`. Editing that launcher affects its next invocation
without a rebuild. `DX_HOME=/opt/dx` and `DX_HOME/bin/dx-mcp` remain compatibility
interfaces; `DX_HOME` alone does not select the live IA component.

To test live instructions, roles, and skills in agent sessions, set the
consumer devcontainer's remote environment:

```jsonc
"remoteEnv": {
  "DX_AGENTS_HOME": "${containerWorkspaceFolder}/.devcontainer/.dx/.devcontainer/components/agents",
  "DX_TOOLS_HOME": "${containerWorkspaceFolder}/.devcontainer/.dx/.devcontainer/components/tools"
}
```

Rebuild once to apply the devcontainer configuration. Use the project
`AGENTS.md` bootstrap from [consumer.md](consumer.md): it resolves `DX_AGENTS_HOME`
from the environment and reads that component's `AGENTS.md`, which loads
`instructions/base.md` and `instructions/git.md` before work and lists roles
and skills by metadata. Resource edits are then read directly from the worktree
when the agent loads them; ask it to reread changed resources in an existing
session. Changing the environment does not configure a client's native
picker. If the client does not read the project `AGENTS.md`, provide it through
context or the initial request. Subagents require client support; otherwise
the current agent applies the selected role and reports that fallback.

This repository's own devcontainer selects `.devcontainer/components/agents`
through `DX_AGENTS_HOME` and `.devcontainer/components/tools` through
`DX_TOOLS_HOME`, using absolute workspace paths. Its root
[AGENTS.md](../AGENTS.md) links directly to the agents submodule entry point.
Task can use the local Taskfile include below. `dx-mcp github` runs GitHub's
official MCP image through Docker and does not use a workspace token.

For Task, temporarily change the consumer's uncommitted include when testing
the live Taskfile:

```yaml
includes:
  dx:
    taskfile: ./.devcontainer/.dx/.devcontainer/components/tools/taskfiles/base.yml
```

Use Go Task 3.53.1 or newer, as supplied by the DX Feature. The local include
does not require remote-host trust. For a remote include, local runs show
Task's normal trust prompt on first use. The reusable validate workflow retains
`TASK_REMOTE_TRUSTED_HOSTS=github.com` for URLs hosted on `github.com`.

Restore the fixed candidate remote include before committing the consumer change:

```yaml
includes:
  dx: https://github.com/Gildraen/dx-tools/raw/v0.1.0-rc.1/taskfiles/base.yml
```

For this URL, run Task with `TASK_REMOTE_TRUSTED_HOSTS=github.com` or accept
its trust prompt. The reusable validation workflow already trusts this host;
see [consumer.md](consumer.md#3-remote-taskfile-optional-shared-helpers).

If the Feature manifest, installation script or installed selector changes,
use the local Feature reference in the consumer's `devcontainer.json` and
rebuild the container:

```jsonc
"features": {
  "./.dx/.devcontainer/src/dx": {}
}
```

The normal loop is `edit Feature -> rebuild container -> test`. Component-only
changes do not require a rebuild once the consumer reads live sources through
`DX_AGENTS_HOME` and `DX_TOOLS_HOME`. Changes to the wrapper installed by
`install.sh` require a rebuild. Installed consumers receive component changes
by selecting a published `agentsVersion` or `toolsVersion` and rebuilding; Feature
implementation changes require a new Feature version.

Run the consumer's `task validate` and `task test` in its devcontainer. The dx
repository CI follows the same model: structural `task validate` runs on the
runner, `task test` runs in `.devcontainer/devcontainer.json`, and
`feature:test` runs directly on the runner's Docker daemon. The dx devcontainer
uses the standard workspace bind mount, so edits in the container stay visible
in the checkout. Run `task feature:test` from the host checkout, where the
Docker daemon can bind-mount the CLI's temporary project paths. With the
standard workspace mount, those paths differ inside the devcontainer.
Reusable GitHub workflows cannot see a local worktree. The portable workflow
test reference is
`Gildraen/ci-workflows/.github/workflows/reusable-validate.yml@v0.1.0-rc.1`
(the same version tag applies to devcontainer-test and maintenance).
Testing changed CI or Remote Taskfiles requires a published ref in their
own repository, not a branch in DX. The current component integration branch
is `feat/component-extraction`; a test include may use
`https://github.com/Gildraen/dx-tools/raw/feat/component-extraction/taskfiles/base.yml`.
Use Task 3.53.1's direct HTTP include with the selected tag for consumption.
Restore the fixed candidate raw URL before committing a consumer change. Restrict trust
to `github.com` for these includes. Do not use global `--yes`. Publication
requires explicit approval.

## Clean up and publish a Feature version

From the main DX worktree, remove the linked worktree only after its changes
are committed or discarded:

```sh
cd ~/projects/dx
git worktree remove ../my-project/.devcontainer/.dx
git worktree prune
```

Open and merge the PR from `feature/my-dx-change` into `main`. For a release,
update `.devcontainer/src/dx/devcontainer-feature.json` to a new stable version
and keep the published-release example in the consumer guide consistent with
that manifest before merging.
PR CI runs validation, both container test suites and native Feature manifest
validation through `devcontainers/action` with `validate-only: "true"`. The
push to `main` publishes only the Feature to GHCR through the same native
action with `publish-features: "true"`. No Git tag
or GitHub release is created. Choosing and increasing the manifest version
remains manual; the CLI skips an already published Feature version.
Git references for workflows and Remote Taskfiles must
exist separately; publishing the Feature does not create or update them.
A new push cancels the previous run. There is no automatic rollback;
inspect any partial GHCR publication before rerunning a failed release.
After merge, the branch can be deleted according to the repository policy.

The commands above are examples, not authorization to discard work or publish.
Commit, push, merge and publication operations require explicit approval.
