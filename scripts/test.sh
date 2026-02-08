#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); echo "PASS: $1"; }
fail() { FAIL=$((FAIL + 1)); echo "FAIL: $1"; }

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

cat > "$tmp_dir/sample.md" <<'EOF'
# Sample

Read [Example](https://example.com) and [Broken](https://example.invalid/not-found).
Local [Anchor](#section) and [Mail](mailto:test@example.com).
EOF

parse_output="$("$SCRIPT_DIR/parse.sh" "$tmp_dir/sample.md")"
if printf '%s\n' "$parse_output" | grep -q "https://example.com"; then
  pass "parse extracts http link"
else
  fail "parse extracts http link"
fi

if "$SCRIPT_DIR/run.sh" --path "$tmp_dir/sample.md" --format summary | grep -q '^total='; then
  pass "run produces summary output"
else
  fail "run produces summary output"
fi

if "$SCRIPT_DIR/run.sh" --path "$tmp_dir/sample.md" --format summary --fail-on-dead >/dev/null 2>&1; then
  fail "fail-on-dead exits non-zero when dead links exist"
else
  pass "fail-on-dead exits non-zero when dead links exist"
fi

echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
