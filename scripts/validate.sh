#!/usr/bin/env bash
set -euo pipefail

timeout_s="${MLC_TIMEOUT:-10}"
user_agent="${MLC_USER_AGENT:-markdown-link-checker/0.1.0}"
input_file=""

show_help() {
  cat <<'EOF'
Usage: validate.sh [--timeout SECONDS] [TSV_FILE]

Validate extracted links from TSV input:
  source_file<TAB>url

Output format (TSV):
  source_file<TAB>url<TAB>result<TAB>http_code<TAB>note
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help)
      show_help
      exit 0
      ;;
    --timeout)
      timeout_s="$2"
      shift 2
      ;;
    *)
      input_file="$1"
      shift
      ;;
  esac
done

run_curl() {
  local url="$1"
  curl -sS -L -A "$user_agent" --max-time "$timeout_s" -o /dev/null -w '%{http_code}' "$url" 2>/dev/null || true
}

process_line() {
  local source_file="$1"
  local url="$2"
  local result code note

  if [[ "$url" =~ ^https?:// ]]; then
    code="$(run_curl "$url")"
    if [[ "$code" =~ ^[0-9]{3}$ ]] && (( code >= 200 && code < 400 )); then
      result="ALIVE"
      note="ok"
    else
      result="DEAD"
      note="http-check-failed"
      [[ -z "$code" ]] && code="000"
    fi
  else
    result="SKIPPED"
    code="-"
    if [[ "$url" =~ ^# ]]; then
      note="anchor"
    elif [[ "$url" =~ ^mailto: ]]; then
      note="mailto"
    elif [[ "$url" =~ ^/ ]]; then
      note="absolute-path"
    else
      note="non-http"
    fi
  fi

  printf '%s\t%s\t%s\t%s\t%s\n' "$source_file" "$url" "$result" "$code" "$note"
}

if [[ -n "$input_file" ]]; then
  while IFS=$'\t' read -r source_file url; do
    [[ -z "${url:-}" ]] && continue
    process_line "$source_file" "$url"
  done <"$input_file"
else
  while IFS=$'\t' read -r source_file url; do
    [[ -z "${url:-}" ]] && continue
    process_line "$source_file" "$url"
  done
fi
