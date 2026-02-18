#!/bin/bash
set -euo pipefail

# Build script for all plugins
# Usage: ./build.sh <plugin-name>

if [ $# -eq 0 ]; then
  echo "Usage: ./build.sh <plugin-name>"
  echo "Example: ./build.sh inbox"
  exit 1
fi

PLUGIN="$1"
PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)/${PLUGIN}"
MANIFEST="${PLUGIN_DIR}/.claude-plugin/plugin.json"

if [ ! -d "$PLUGIN_DIR" ]; then
  echo "Error: plugin directory '${PLUGIN}' not found" >&2
  exit 1
fi

if [ ! -f "$MANIFEST" ]; then
  echo "Error: ${MANIFEST} not found" >&2
  exit 1
fi

VERSION=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['version'])" "$MANIFEST")
DIST_DIR="$(cd "$(dirname "$0")" && pwd)/dist/${PLUGIN}/v${VERSION}"

mkdir -p "$DIST_DIR"
(cd "$PLUGIN_DIR" && zip -r "${DIST_DIR}/${PLUGIN}.zip" . -x '*.DS_Store' -x 'tmp/*')

echo "Created ${DIST_DIR}/${PLUGIN}.zip"