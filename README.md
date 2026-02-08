# markdown-link-checker

Check markdown links in files or directories using composable shell scripts.

## Prerequisites
- `bash`
- `curl`
- `awk`
- `sed`
- `grep`
- `find`

## Install
```bash
./scripts/install.sh
```

## Quick Start
```bash
./scripts/run.sh --path docs
```

Show a table report:
```bash
./scripts/run.sh --path docs --format table
```

Compose scripts directly:
```bash
./scripts/parse.sh docs | ./scripts/validate.sh --timeout 8 | ./scripts/format.sh --format summary
```

## Tests
```bash
./scripts/test.sh
```
