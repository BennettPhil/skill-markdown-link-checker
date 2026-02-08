---
name: markdown-link-checker
description: Scans markdown files for dead links (remote URLs and local file references) with concurrent checking.
version: 0.1.0
license: Apache-2.0
---

# Markdown Link Checker

## Purpose

Scan markdown files or directories for broken links. Checks both remote HTTP URLs (concurrently) and local file references. Reports dead links with file location and line numbers. Works on single files or entire doc directories.

## Quick Start

```bash
$ ./scripts/run.sh README.md
  ✓ [OK] https://example.com
  ✗ [DEAD] https://broken-link.example
         README.md:5 "Some Link"

Total: 2 links (1 ok, 1 dead)
```

## Usage Examples

### Check a Directory

```bash
$ ./scripts/run.sh docs/
```

### JSON Output

```bash
$ ./scripts/run.sh README.md --format json
```

### Local Links Only

```bash
$ ./scripts/run.sh docs/ --local-only
```

### Adjust Concurrency

```bash
$ ./scripts/run.sh docs/ --concurrency 10 --timeout 5
```

## Options Reference

| Flag              | Default | Description                         |
|-------------------|---------|-------------------------------------|
| `--format FMT`    | text    | Output format: text, json           |
| `--local-only`    | false   | Only check local file references    |
| `--remote-only`   | false   | Only check remote URLs              |
| `--concurrency N` | 5       | Max concurrent HTTP requests        |
| `--timeout N`     | 10      | Request timeout in seconds          |
| `--help`          |         | Show usage                          |

## Error Handling

| Exit Code | Meaning             |
|-----------|---------------------|
| 0         | All links OK        |
| 1         | Usage/input error   |
| 2         | Dead links found    |

## Validation

Run `scripts/test.sh` to verify correctness (6 assertions).
