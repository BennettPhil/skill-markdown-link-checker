#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'EOF'
Usage: parse.sh [PATH...]

Extract markdown links from files or directories.
Output format (TSV):
  source_file<TAB>url

If no PATH is provided, reads markdown content from stdin and emits source as "-".
EOF
}

extract_from_file() {
  local file="$1"
  sed -nE 's/.*\[[^]]+\]\(([^)[:space:]]+)\).*/\1/p' "$file" | sed '/^$/d' | while IFS= read -r url; do
    printf '%s\t%s\n' "$file" "$url"
  done
  grep -oE 'https?://[^[:space:])>"]+' "$file" | while IFS= read -r url; do
    printf '%s\t%s\n' "$file" "$url"
  done
}

if [[ "${1:-}" == "--help" ]]; then
  show_help
  exit 0
fi

if [[ "$#" -eq 0 ]]; then
  tmp="$(mktemp)"
  cat >"$tmp"
  extract_from_file "$tmp" | sed $'s#^\t#-\t#'
  rm -f "$tmp"
  exit 0
fi

for path in "$@"; do
  if [[ -d "$path" ]]; then
    find "$path" -type f \( -name '*.md' -o -name '*.markdown' \) | while IFS= read -r file; do
      extract_from_file "$file"
    done
  elif [[ -f "$path" ]]; then
    extract_from_file "$path"
  else
    echo "parse.sh: path not found: $path" >&2
    exit 1
  fi
done
