#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
timeout_s="${MLC_TIMEOUT:-10}"
format="summary"
fail_on_dead=0
paths=()

show_help() {
  cat <<'EOF'
Usage: run.sh [--path PATH]... [--timeout SECONDS] [--format summary|table|raw] [--fail-on-dead]

Run markdown link checks across one or more files/directories.
If no --path is provided, defaults to current directory.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help)
      show_help
      exit 0
      ;;
    --path)
      paths+=("$2")
      shift 2
      ;;
    --timeout)
      timeout_s="$2"
      shift 2
      ;;
    --format)
      format="$2"
      shift 2
      ;;
    --fail-on-dead)
      fail_on_dead=1
      shift
      ;;
    *)
      echo "run.sh: unknown argument '$1'" >&2
      exit 1
      ;;
  esac
done

if [[ "${#paths[@]}" -eq 0 ]]; then
  paths=(.)
fi

tmp_results="$(mktemp)"
trap 'rm -f "$tmp_results"' EXIT

"$SCRIPT_DIR/parse.sh" "${paths[@]}" \
  | "$SCRIPT_DIR/validate.sh" --timeout "$timeout_s" \
  > "$tmp_results"

"$SCRIPT_DIR/format.sh" --format "$format" "$tmp_results"

dead_count="$(awk -F'\t' '$3=="DEAD"{c++} END{print c+0}' "$tmp_results")"
if [[ "$fail_on_dead" -eq 1 && "$dead_count" -gt 0 ]]; then
  exit 2
fi
