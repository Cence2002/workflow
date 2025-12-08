#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/config.sh"

NAME="${1:-}"

if [ -z "$NAME" ]; then
  echo "Usage: scripts/create-project.sh <project-name>" >&2
  exit 1
fi

PROJECT_DIR="$PROJECTS_ROOT/$NAME"

if [ -e "$PROJECT_DIR" ]; then
  echo "[create-project] Destination already exists: $PROJECT_DIR" >&2
  exit 1
fi

echo "[create-project] Creating project at $PROJECT_DIR"
mkdir -p "$PROJECT_DIR"

# Empty README
: > "$PROJECT_DIR/README.md"

# Minimal Python devcontainer
mkdir -p "$PROJECT_DIR/.devcontainer"
cat > "$PROJECT_DIR/.devcontainer/devcontainer.json" <<EOF
{
  "name": "${NAME}",
  "image": "python:3",
  "features": {},
  "mounts": [
    "source=\${localEnv:HOME}/.ssh,target=/root/.ssh,type=bind,consistency=cached"
  ]
}
EOF

# Initialise git repo
git -C "$PROJECT_DIR" init

echo "[create-project] Done. New project created at: $PROJECT_DIR"
echo "[create-project] You can now open this folder in VS Code and use 'Reopen in Container'."
