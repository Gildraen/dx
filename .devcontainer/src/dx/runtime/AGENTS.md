# DX shared agent guidance

This directory is the shared DX runtime, not a consumer project. Its Markdown
resources do not require a particular AI client, model, or editor integration.

## Instruction hierarchy

The project's `AGENTS.md` loads this document once before selecting a role or
workflow. The shared rules and delegation policy below apply to every resource
under this directory. Roles and skills contain only their specific guidance;
they do not repeat the common bootstrap. Pass this established context to
subagents together with the selected role.

Keep each rule at the narrowest shared level that owns it:

- This guide and the shared instructions own cross-role execution rules.
- Agents own role boundaries, workflow selection and composition, and rules
	shared by their workflows.
- Skills own one bounded procedure, its specific checks, and its result.

Do not repeat inherited rules in each child resource. A skill may be selected
directly; load its owning role to establish the relevant workflow context.
Read only the skills needed for the current task, not every available skill.

## Common execution rules

Establish the requested scope and whether the task is analysis or execution
before acting. A review, audit, verification, or plan does not authorize edits;
report proposed changes instead. An implementation request authorizes only the
changes needed for that request. Do not widen scope without agreement.

Ground conclusions and changes in the relevant sources, contracts, and checks.
Distinguish confirmed defects from ambiguity and optional improvements. Prefer
the smallest justified change, preserve unrelated work, and do not rewrite
resources merely to rephrase them. Validate changes with the closest available
check before broader validation. Report the result, checks actually run, and
remaining limitations; do not claim unperformed validation.

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

Also inspect the project's `.agents/agents/*.md` and
`.agents/skills/*/SKILL.md` from the repository root. Read each resource's
`name` and `description` metadata and load relevant project resources using the
same selection procedure. The shared and project resource sets are additive;
do not copy project resources into `DX_HOME` or assume a native client picker
discovers these paths.

Project-specific roles and skills stay in the project's `.agents/agents/` and
`.agents/skills/` only. These are the sole canonical locations for
project-specific resources. Do not keep duplicate copies in client-specific
directories; clients that do not discover these paths use this explicit
loading procedure.

## Delegate focused work

Actively look for bounded subtasks that benefit from specialized expertise or
a narrower context, and delegate them to subagents even when coordination
takes longer. Prefer focused assignments over having one agent accumulate
unrelated context. Compose several focused skills when a task spans distinct
procedures; the selected role decides their order and integration. Run dependent
steps sequentially and independent bounded assignments in parallel.

If the client cannot run a subagent, apply the selected role and skills in the
current agent and report this fallback. If no existing agent fits a subtask,
create a temporary
specialized agent for it; tell the user when creating one is necessary and
briefly state its intended specialty and scope. Give each subagent its scope,
applicable rules, selected role and skills, expected result, and whether edits
are allowed. Give concurrent writers disjoint file ownership. A subagent must
not delegate its unchanged assignment again; further delegation needs a smaller
distinct scope and must be supported by the client. The main agent remains
responsible for integration, validation, and reporting. Delegation does not
authorize a commit or push.

## Runtime location

Use the process environment's `DX_HOME` to locate this document. The Feature
sets it to `/opt/dx`; development sessions may explicitly select live sources.
Changing `DX_HOME` does not configure the client's native discovery mechanism.
If the client does not load the project's `AGENTS.md`, explicitly provide that
file through the client's context or initial request before starting work.
