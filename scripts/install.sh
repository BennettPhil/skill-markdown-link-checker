#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'EOF'
Usage: install.sh [--help]

Checks required dependencies for markdown-link-checker.
EOF
}

if [[ "${1:-}" == "--help" ]]; then
  show_help
  exit 0
fi

required=(awk sed grep curl find mktemp)
missing=()

for bin in "${required[@]}"; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    missing+=("$bin")
  fi
done

if [[ "${#missing[@]}" -gt 0 ]]; then
  echo "Missing dependencies: ${missing[*]}"
  echo "Install these tools with your system package manager and rerun."
  exit 1
fi

echo "Environment ready: all dependencies found."
