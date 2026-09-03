# Project agent instructions

Load the shared DX agent instructions first:

- when a DX dogfood checkout exists (`./.dx/.devcontainer/src/dx/runtime/agents/`), use those files;
- otherwise use the DX runtime installed in the devcontainer (`$DX_HOME/agents/`,
  `/opt/dx/agents/` by default).

Then apply the project-specific rules below.

## Project-specific rules

- Describe here only what is genuinely specific to this repository
  (business rules, ports, services, test commands).
