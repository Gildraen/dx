# Shared DX skills

This directory is the canonical home for reusable Gildraen skills that are
versioned with `dx` and installed to `$DX_HOME/skills/` by the Dev Container
Feature.

Keep only cross-repository workflows here. Project-specific skills stay in the
consumer repository under `.agents/skills/`.

## Selection and composition

Follow the [runtime guide](../AGENTS.md#select-a-role-or-workflow) to select
resources by their metadata; directory contents are authoritative, not a
central catalogue. Each skill links to its owning role, which links back to
its workflows. Even when a skill is requested directly, read its owning role
to establish the workflow context.

The role selects and composes only the skills needed for the task, deciding
their order and how to integrate their results; do not load every skill.
Shared execution rules are inherited from the runtime guide and instructions,
domain rules from the role. A skill contains one bounded procedure, its
specific checks, and its result, without repeating inherited rules.

For bounded subagent assignments and the fallback when the client cannot run
subagents, follow the [delegation policy](../AGENTS.md#delegate-focused-work).
These are explicit loading instructions, not a native client discovery
mechanism.
