#!/usr/bin/env bash
set -euo pipefail

format="summary"
input_file=""

show_help() {
  cat <<'EOF'
Usage: format.sh [--format summary|table|raw] [TSV_FILE]

Formats validation TSV rows:
  source_file<TAB>url<TAB>result<TAB>http_code<TAB>note
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help)
      show_help
      exit 0
      ;;
    --format)
      format="$2"
      shift 2
      ;;
    *)
      input_file="$1"
      shift
      ;;
  esac
done

if [[ -n "$input_file" ]]; then
  input="$(cat "$input_file")"
else
  input="$(cat)"
fi

case "$format" in
  raw)
    printf '%s\n' "$input"
    ;;
  table)
    printf '%s\n' "SOURCE | URL | RESULT | HTTP | NOTE"
    printf '%s\n' "--- | --- | --- | --- | ---"
    printf '%s\n' "$input" | awk -F'\t' '{printf "%s | %s | %s | %s | %s\n",$1,$2,$3,$4,$5}'
    ;;
  summary)
    total="$(printf '%s\n' "$input" | awk 'NF>0{c++} END{print c+0}')"
    alive="$(printf '%s\n' "$input" | awk -F'\t' '$3=="ALIVE"{c++} END{print c+0}')"
    dead="$(printf '%s\n' "$input" | awk -F'\t' '$3=="DEAD"{c++} END{print c+0}')"
    skipped="$(printf '%s\n' "$input" | awk -F'\t' '$3=="SKIPPED"{c++} END{print c+0}')"
    checked=$((alive + dead))
    printf 'total=%s\nchecked=%s\nalive=%s\ndead=%s\nskipped=%s\n' "$total" "$checked" "$alive" "$dead" "$skipped"
    ;;
  *)
    echo "format.sh: invalid format '$format'" >&2
    exit 1
    ;;
esac
