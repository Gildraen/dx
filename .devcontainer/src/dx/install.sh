#!/usr/bin/env bash
# Dev Container Feature install script.
# Copies the versioned DX runtime into DX_HOME.
set -euo pipefail

DX_HOME="/opt/dx"
FEATURE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$DX_HOME"
cp -R "$FEATURE_DIR/runtime/." "$DX_HOME/"
find "$DX_HOME/bin" -maxdepth 1 -type f -exec chmod +x {} \;

# Expose shared resources at Copilot's native user locations. Keep the runtime
# canonical under DX_HOME and preserve any user-owned paths or entries.
if [[ -n "${_REMOTE_USER_HOME:-}" && -n "${_REMOTE_USER:-}" ]]; then
	remote_group="$(id -gn "$_REMOTE_USER")"
	copilot_root="$_REMOTE_USER_HOME/.copilot"
	copilot_agents="$copilot_root/agents"
	copilot_skills="$copilot_root/skills"

	ensure_directory() {
		local directory="$1"

		if [[ -L "$directory" || ( -e "$directory" && ! -d "$directory" ) ]]; then
			printf 'Skipping Copilot resource path that is not a directory: %s\n' "$directory" >&2
			return 1
		fi
		if [[ ! -d "$directory" ]]; then
			mkdir "$directory"
			chown "$_REMOTE_USER:$remote_group" "$directory"
		fi
	}

	if ensure_directory "$copilot_root"; then
		agents_ready=0
		skills_ready=0
		ensure_directory "$copilot_agents" && agents_ready=1
		ensure_directory "$copilot_skills" && skills_ready=1

		link_resource() {
			local source="$1"
			local destination="$2"

			if [[ -L "$destination" && "$(readlink -f "$destination")" == "$(readlink -f "$source")" ]]; then
				return
			fi
			if [[ -e "$destination" || -L "$destination" ]]; then
				printf 'Keeping existing Copilot resource: %s\n' "$destination" >&2
				return
			fi
			ln -s "$source" "$destination"
			chown -h "$_REMOTE_USER:$remote_group" "$destination"
		}

		if [[ $agents_ready -eq 1 ]]; then
			for agent in "$DX_HOME"/agents/*.md; do
				[[ -f "$agent" ]] || continue
				link_resource "$agent" "$copilot_agents/$(basename "$agent")"
			done
		fi
		if [[ $skills_ready -eq 1 ]]; then
			for skill in "$DX_HOME"/skills/*/; do
				[[ -f "${skill}SKILL.md" ]] || continue
				link_resource "${skill%/}" "$copilot_skills/$(basename "$skill")"
			done
		fi
	fi
fi

install -m 0755 /dev/stdin /usr/local/bin/dx-mcp <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [ -z "${DX_HOME:-}" ] && [ -d "$PWD/.devcontainer/.dx/.devcontainer/src/dx/runtime" ]; then
	DX_HOME="$PWD/.devcontainer/.dx/.devcontainer/src/dx/runtime"
else
	DX_HOME="${DX_HOME:-/opt/dx}"
fi

export DX_HOME
exec "$DX_HOME/bin/dx-mcp" "$@"
EOF

echo "dx runtime installed at $DX_HOME"
