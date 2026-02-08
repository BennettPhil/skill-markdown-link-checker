---
name: markdown-link-checker
description: Check markdown links in files or folders with composable Unix scripts.
version: 0.1.0
license: Apache-2.0
---

# Markdown Link Checker Skill

## Purpose
This skill scans markdown files, extracts links, validates remote URLs, and reports alive, dead, and skipped links. It is designed as small composable scripts so each step can run independently or in pipelines.

## Scripts Overview
| Script | Purpose |
| --- | --- |
| `scripts/install.sh` | Checks required tools and validates environment readiness. |
| `scripts/parse.sh` | Extracts markdown links from files/directories and emits TSV. |
| `scripts/validate.sh` | Validates extracted links and emits normalized result TSV. |
| `scripts/format.sh` | Formats validation results as summary, table, or raw output. |
| `scripts/run.sh` | Main entrypoint that orchestrates parse -> validate -> format. |
| `scripts/test.sh` | Runs basic checks to verify behavior and output. |

## Pipeline Examples
Check a docs folder with default summary output:

```bash
./scripts/run.sh --path docs
```

Emit a readable table:

```bash
./scripts/run.sh --path docs --format table
```

Use utilities independently:

```bash
./scripts/parse.sh docs | ./scripts/validate.sh --timeout 8 | ./scripts/format.sh --format summary
```

## Inputs and Outputs
- `scripts/parse.sh`
- Input: markdown file path(s), directory path(s), or stdin markdown content
- Output: TSV rows `source_file<TAB>url`

- `scripts/validate.sh`
- Input: TSV from stdin or file path argument
- Output: TSV rows `source_file<TAB>url<TAB>result<TAB>http_code<TAB>note`

- `scripts/format.sh`
- Input: validation TSV from stdin or file path argument
- Output: summary text, table, or raw TSV

- `scripts/run.sh`
- Input: one or more `--path` values
- Output: formatted report to stdout
- Exit code: `0` on success, `2` if `--fail-on-dead` and dead links found

## Environment Variables
- `MLC_TIMEOUT` - Default HTTP timeout in seconds for `validate.sh` and `run.sh` (default: `10`)
- `MLC_USER_AGENT` - User-Agent header for HTTP checks (default: `markdown-link-checker/0.1.0`)
