# Dogfooding a `dx` change in a real project

Dogfood uses a real Git worktree of `Gildraen/dx` inside a consumer project.
The worktree is created by the DX repository, not by the consumer repository,
and `.dx` is local-only state.

## Create the worktree

For this layout:

```text
~/projects/dx/
~/projects/Niki/
```

create a new branch and worktree from the DX repository:

```sh
cd ~/projects/dx
git switch main
git pull --ff-only
git worktree add -b feature/my-dx-change ../Niki/.dx main
```

The command creates `Niki/.dx` as a linked worktree of `dx` on
`feature/my-dx-change`. Verify the ownership from the worktree itself:

```sh
cd ~/projects/Niki/.dx
git status
git remote -v
git branch --show-current
```

Changes under `Niki/.dx` belong to `Gildraen/dx`, not to `Niki`. Exclude the
worktree only in the consumer clone:

```sh
cd ~/projects/Niki
echo '.dx/' >> .git/info/exclude
git status --short
```

## Use the live DX sources

From `Niki`, point the runtime lookup at the worktree for the current shell or
devcontainer session:

```sh
cd ~/projects/Niki
export DX_HOME="$PWD/.dx/src/dx/runtime"
```

Runtime selection is deterministic:

```text
DX_HOME explicitly set  -> that directory
otherwise .dx exists    -> <workspace>/.dx/src/dx/runtime
otherwise               -> /opt/dx
```

The installed `/usr/local/bin/dx-mcp` is only a small selector. It resolves
this order on every invocation and then executes the selected runtime's
`bin/dx-mcp`. Editing `.dx/src/dx/runtime/bin/dx-mcp` therefore affects the
next `dx-mcp` invocation immediately; no rebuild or release is needed. The
Feature test exercises both the `.dx` selection and the explicit override.

The shared agent bootstrap already prefers `./.dx/src/dx/runtime/agents/` and
otherwise falls back to `$DX_HOME/agents/` or `/opt/dx/agents/`. Runtime files
such as agent instructions, the Task helpers, and `dx-mcp` are therefore live
from the worktree. `dx-mcp github` runs GitHub's official MCP image through
Docker and does not use a workspace token.

For Task, temporarily change the consumer's uncommitted include when testing
the live Taskfile:

```yaml
includes:
  dx:
    taskfile: ./.dx/src/dx/runtime/taskfiles/base.yml
```

Use Go Task `v3.53.0` or newer. In CI, the reusable validate workflow trusts
only `github.com` through `TASK_REMOTE_TRUSTED_HOSTS=github.com`; local runs
show Task's normal trust prompt on first use.

Restore the versioned remote include before committing the consumer change:

```yaml
includes:
  dx: https://github.com/Gildraen/dx.git//src/dx/runtime/taskfiles/base.yml?ref=v1.0.0
```

If the Feature itself changes (`devcontainer-feature.json` or `install.sh`),
use the local Feature reference in the consumer's `devcontainer.json` and
rebuild the container:

```jsonc
"features": {
  "../.dx/src/dx": {}
}
```

The normal loop is `edit Feature -> rebuild container -> test`. Runtime-only
changes do not require a rebuild when the consumer reads them through
`DX_HOME`.

Run the consumer's `task validate` and `task test`. Reusable GitHub workflows
cannot see a local worktree: push `feature/my-dx-change`, temporarily reference
`@feature/my-dx-change` from the consumer, run its CI, then restore the released
tag.

## Finish dogfood and release

From the main DX worktree, remove the linked worktree only after its changes
are committed or discarded:

```sh
cd ~/projects/dx
git worktree remove ../Niki/.dx
git worktree prune
```

Open and merge the PR from `feature/my-dx-change` into `main`. For a release,
update `src/dx/devcontainer-feature.json` to the release version, merge it,
then create and push the matching tag. For example, manifest `1.1.0` requires
tag `v1.1.0`; the release workflow rejects mismatches before publishing.
After merge, the branch can be deleted according to the repository policy.

No commit, push, merge, tag, or release is performed by this guide.
