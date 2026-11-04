# DX shared agent guidance

This directory is the shared DX runtime, not a consumer project. Its Markdown
resources do not require a particular AI client, model, or editor integration.

## Instruction hierarchy

The project's `AGENTS.md` loads this document once before selecting a role or
workflow. The shared rules and delegation policy below apply to every resource
under this directory. Roles and skills contain only their specific guidance;
they do not repeat the common bootstrap. Pass this established context to
subagents together with the selected role.

## Load the shared rules

Before working on a project, read [base.md](instructions/base.md) and
[git.md](instructions/git.md). These rules apply to all DX work; they are not
activated by editor-specific metadata. Read the project's own `AGENTS.md` for
additional constraints. If required rules cannot be read, report the missing
resource instead of silently continuing without it.

## Select a role or workflow

List the Markdown files in `agents/` and read their `name` and `description`
metadata to select a relevant role. Read the complete role before using it.
List `skills/*/SKILL.md` to find reusable workflows by their metadata, then
read the selected workflow and its referenced resources as needed. Directory
contents are authoritative; no central list of roles or workflows is required.

Project-specific roles and skills stay in the project's `.agents/agents/` and
`.agents/skills/`. When present, list and select them by the same metadata
procedure. They supplement this runtime rather than duplicating it.

## Delegate when supported

If the client supports subagents, delegate focused work using the selected
role's instructions. Give each subagent its scope, applicable rules, expected
result, and whether edits are allowed. Parallelize only independent work.
The main agent remains responsible for integration, validation, and reporting.
Delegation does not authorize a commit or push.

If the client cannot run a subagent with these instructions, apply the role
in the current agent and report that fallback. File availability does not
guarantee native picker discovery, automatic skill loading, or subagent support.

## Runtime location

Use the process environment's `DX_HOME` to locate this document. The Feature
sets it to `/opt/dx`; development sessions may explicitly select live sources.
Changing `DX_HOME` does not configure the client's native discovery mechanism.
If the client does not load the project's `AGENTS.md`, explicitly provide that
file through the client's context or initial request before starting work.
