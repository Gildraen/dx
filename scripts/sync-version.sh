#!/bin/bash
# Script to sync version from package.json to devcontainer-feature.json
# Called by semantic-release via git commit hook

set -euo pipefail

PACKAGE_VERSION=$(node -p "require('./package.json').version")
FEATURE_MANIFEST="./.devcontainer/src/dx/devcontainer-feature.json"

# Update the version in the Feature manifest
node -e "
const fs = require('fs');
const manifest = require('${FEATURE_MANIFEST}');
manifest.version = '${PACKAGE_VERSION}';
fs.writeFileSync('${FEATURE_MANIFEST}', JSON.stringify(manifest, null, 4) + '\n');
"

echo "✅ Synced Feature manifest version to ${PACKAGE_VERSION}"
