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

create a new branch and worktree from the DX repository:

```sh
cd ~/projects/dx
git switch main
git pull --ff-only
git worktree add -b feature/my-dx-change ../my-project/.devcontainer/.dx main
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

From the consumer, point the runtime lookup at the worktree for the current shell or
devcontainer session:

```sh
cd ~/projects/my-project
export DX_HOME="$PWD/.devcontainer/.dx/.devcontainer/src/dx/runtime"
```

The installed `dx-mcp` launcher's runtime selection is deterministic:

```text
DX_HOME explicitly set  -> that directory
otherwise .devcontainer/.dx exists -> <workspace>/.devcontainer/.dx/.devcontainer/src/dx/runtime
otherwise               -> /opt/dx
```

The Feature sets `DX_HOME=/opt/dx` by default, so dogfood must explicitly
override it as above. The worktree fallback when it is unset belongs to the
`dx-mcp` launcher, not the agent bootstrap: that bootstrap uses `/opt/dx` when
`DX_HOME` is absent.

The installed `/usr/local/bin/dx-mcp` is only a small selector. It resolves
this order on every invocation and then executes the selected runtime's
`bin/dx-mcp`. Editing `.devcontainer/.dx/.devcontainer/src/dx/runtime/bin/dx-mcp` therefore affects the
next `dx-mcp` invocation immediately; no rebuild or release is needed. The
Feature test exercises both the `.devcontainer/.dx` selection and the explicit override.

To test live instructions, roles, and skills in agent sessions, set the
consumer devcontainer's remote environment:

```jsonc
"remoteEnv": {
  "DX_HOME": "${containerWorkspaceFolder}/.devcontainer/.dx/.devcontainer/src/dx/runtime"
}
```

Rebuild once to apply the devcontainer configuration. Use the project
`AGENTS.md` bootstrap from [consumer.md](consumer.md): it resolves `DX_HOME`
from the environment and reads that runtime's `AGENTS.md`, which loads
`instructions/base.md` and `instructions/git.md` before work and lists roles
and skills by metadata. Resource edits are then read directly from the worktree
when the agent loads them; ask it to reread changed resources in an existing
session. Changing the environment does not configure a client's native
picker. If the client does not read the project `AGENTS.md`, provide it through
context or the initial request. Subagents require client support; otherwise
the current agent applies the selected role and reports that fallback.

This repository's own devcontainer sets `remoteEnv.DX_HOME` to
`${containerWorkspaceFolder}/.devcontainer/src/dx/runtime`, and its root
[AGENTS.md](../AGENTS.md) links directly to that local runtime entry point.
Task can use the local Taskfile include below. `dx-mcp github` runs GitHub's
official MCP image through Docker and does not use a workspace token.

For Task, temporarily change the consumer's uncommitted include when testing
the live Taskfile:

```yaml
includes:
  dx:
    taskfile: ./.devcontainer/.dx/.devcontainer/src/dx/runtime/taskfiles/base.yml
```

Use Go Task 3.53.1 or newer, as supplied by the DX Feature. The local include
does not require remote-host trust. For a remote include, local runs show
Task's normal trust prompt on first use; the reusable validate workflow sets
`TASK_REMOTE_TRUSTED_HOSTS=github.com` in CI.

Restore the released remote include before committing the consumer change:

```yaml
includes:
  dx: https://github.com/Gildraen/dx.git//.devcontainer/src/dx/runtime/taskfiles/base.yml?ref=<released-tag>
```

If the Feature manifest, installation script or installed selector changes,
use the local Feature reference in the consumer's `devcontainer.json` and
rebuild the container:

```jsonc
"features": {
  "./.dx/.devcontainer/src/dx": {}
}
```

The normal loop is `edit Feature -> rebuild container -> test`. Runtime-only
changes under the selected runtime do not require a rebuild once the consumer
reads live sources through `DX_HOME`. Changes to the selector installed by
`install.sh` require a rebuild. Stable consumers read the snapshot at `/opt/dx`;
they need an updated Feature release and a rebuild to receive those changes.

Run the consumer's `task validate` and `task test` in its devcontainer. The dx
repository CI follows the same model: structural `task validate` runs on the
runner, `task test` runs in `.devcontainer/devcontainer.json`, and
`feature:test` runs directly on the runner's Docker daemon. The dx devcontainer
uses the standard workspace bind mount, so edits in the container stay visible
in the checkout. Run `task feature:test` from the host checkout, where the
Docker daemon can bind-mount the CLI's temporary project paths. With the
standard workspace mount, those paths differ inside the devcontainer.
Reusable GitHub workflows cannot see a local worktree:
push `feature/my-dx-change`, temporarily reference
`@feature/my-dx-change` from the consumer, run its CI, then restore the released
tag. A Remote Taskfile can similarly use `?ref=feature/my-dx-change` once that
branch exists on GitHub. Keep the GitHub-only trust setting in CI; do not use
global `--yes`. Branch publication requires explicit approval.

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
and update the matching Feature reference in `docs/consumer.md` before merging.
PR CI runs validation, both container test suites and native Feature manifest
validation through `devcontainers/action` with `validate-only: "true"`. The
push to `main` publishes only the Feature to GHCR through the same native
action with `publish-features: "true"`. No Git tag
or GitHub release is created. Choosing and increasing the manifest version
remains manual; the CLI skips an already published Feature version.
Git references for workflows, Remote Taskfiles and the Renovate preset must
exist separately; publishing the Feature does not create or update them.
A new push cancels the previous run. There is no automatic rollback;
inspect any partial GHCR publication before rerunning a failed release.
After merge, the branch can be deleted according to the repository policy.

The commands above are examples, not authorization to discard work or publish.
Commit, push, merge and publication operations require explicit approval.
