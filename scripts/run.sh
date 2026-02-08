#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${1:-}" = "--help" || $# -eq 0 ]]; then
  if [[ "${1:-}" = "--help" ]]; then
    cat <<'EOF' >&2
Usage: run.sh <FILE|DIR> [OPTIONS]

Checks markdown files for dead links (both remote URLs and local file refs).

Options:
  --format FORMAT     Output format: text, json (default: text)
  --local-only        Only check local file references
  --remote-only       Only check remote HTTP links
  --concurrency N     Max concurrent requests (default: 5)
  --timeout N         Request timeout in seconds (default: 10)
  --help              Show this help message

Examples:
  run.sh README.md
  run.sh docs/ --format json
  run.sh *.md --local-only
EOF
    exit 0
  fi
  echo "Error: No files specified. Use --help for usage." >&2
  exit 1
fi

exec python3 "$SCRIPT_DIR/check_links.py" "$@"
