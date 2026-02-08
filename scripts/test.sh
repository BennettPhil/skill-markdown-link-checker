#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN="$SCRIPT_DIR/run.sh"
PASS=0; FAIL=0; TOTAL=0
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

assert_contains() {
  local desc="$1" needle="$2" haystack="$3"
  ((TOTAL++))
  if echo "$haystack" | grep -qF -- "$needle"; then
    ((PASS++)); echo "  PASS: $desc"
  else
    ((FAIL++)); echo "  FAIL: $desc (output missing '$needle')"
  fi
}

assert_exit_code() {
  local desc="$1" expected="$2"
  shift 2
  local output
  set +e; output=$("$@" 2>&1); local actual=$?; set -e
  ((TOTAL++))
  if [ "$expected" -eq "$actual" ]; then
    ((PASS++)); echo "  PASS: $desc"
  else
    ((FAIL++)); echo "  FAIL: $desc (expected exit $expected, got $actual)"
  fi
}

echo "=== Tests for markdown-link-checker ==="

# Create test files
cat > "$TMPDIR/good.md" <<'MD'
# Test Doc
[Google](https://www.google.com)
[Example](https://example.com)
MD

cat > "$TMPDIR/bad.md" <<'MD'
# Bad Links
[Broken](https://thisdomaindoesnotexist12345.com)
[Good](https://example.com)
MD

cat > "$TMPDIR/local.md" <<'MD'
# Local Links
[Relative](./good.md)
[Missing](./nonexistent.md)
MD

echo "Core:"
# Test with good links
result=$("$RUN" "$TMPDIR/good.md" 2>&1 || true)
assert_contains "finds links in markdown" "google.com" "$result"

# Test help
echo "Help:"
result=$("$RUN" --help 2>&1)
assert_contains "help flag works" "Usage:" "$result"

# Test no args
echo "Input validation:"
assert_exit_code "fails with no args" 1 "$RUN"

# Test nonexistent file
assert_exit_code "fails with missing file" 1 "$RUN" "$TMPDIR/nonexistent.md"

# Test local links
echo "Local links:"
result=$("$RUN" "$TMPDIR/local.md" --local-only 2>&1 || true)
assert_contains "detects local link" "good.md" "$result"

# Test JSON output
echo "Format:"
result=$("$RUN" "$TMPDIR/good.md" --format json 2>&1 || true)
assert_contains "json output has url field" '"url"' "$result"

echo ""
echo "=== Results: $PASS/$TOTAL passed ==="
[ "$FAIL" -eq 0 ] || { echo "BLOCKED: $FAIL test(s) failed"; exit 1; }
