#!/usr/bin/env python3
"""Markdown link checker - finds and validates links in markdown files."""

import re, sys, json, os, argparse
from urllib.request import urlopen, Request
from urllib.error import URLError, HTTPError
from concurrent.futures import ThreadPoolExecutor, as_completed

LINK_PATTERN = re.compile(r'\[([^\]]*)\]\(([^)]+)\)')
TIMEOUT = 10


def extract_links(filepath):
    """Extract all markdown links from a file."""
    links = []
    with open(filepath) as f:
        for line_num, line in enumerate(f, 1):
            for match in LINK_PATTERN.finditer(line):
                text, url = match.group(1), match.group(2)
                # Skip anchor-only links
                if url.startswith('#'):
                    continue
                links.append({
                    'file': filepath,
                    'line': line_num,
                    'text': text,
                    'url': url,
                    'is_local': not url.startswith(('http://', 'https://', 'mailto:'))
                })
    return links


def check_remote_link(link):
    """Check if a remote URL is reachable."""
    url = link['url']
    try:
        req = Request(url, method='HEAD', headers={'User-Agent': 'markdown-link-checker/0.1'})
        with urlopen(req, timeout=TIMEOUT) as resp:
            link['status'] = resp.status
            link['ok'] = True
    except HTTPError as e:
        link['status'] = e.code
        link['ok'] = e.code < 400
    except (URLError, OSError, ValueError) as e:
        link['status'] = 0
        link['ok'] = False
        link['error'] = str(e)
    return link


def check_local_link(link, base_dir):
    """Check if a local file reference exists."""
    url = link['url']
    # Remove query string and anchors
    clean = url.split('#')[0].split('?')[0]
    target = os.path.normpath(os.path.join(base_dir, clean))
    link['ok'] = os.path.exists(target)
    link['status'] = 200 if link['ok'] else 404
    return link


def main():
    parser = argparse.ArgumentParser(description='Check links in markdown files')
    parser.add_argument('paths', nargs='*', help='Markdown files or directories')
    parser.add_argument('--format', choices=['text', 'json'], default='text')
    parser.add_argument('--local-only', action='store_true', help='Only check local file links')
    parser.add_argument('--remote-only', action='store_true', help='Only check remote HTTP links')
    parser.add_argument('--concurrency', type=int, default=5, help='Max concurrent requests')
    parser.add_argument('--timeout', type=int, default=10, help='Request timeout in seconds')
    args = parser.parse_args()

    if not args.paths:
        print('Error: No files specified. Use --help for usage.', file=sys.stderr)
        sys.exit(1)

    global TIMEOUT
    TIMEOUT = args.timeout

    # Collect all markdown files
    md_files = []
    for path in args.paths:
        if os.path.isfile(path):
            md_files.append(path)
        elif os.path.isdir(path):
            for root, dirs, files in os.walk(path):
                for f in files:
                    if f.endswith(('.md', '.markdown', '.mdx')):
                        md_files.append(os.path.join(root, f))
        else:
            print(f'Error: Not found: {path}', file=sys.stderr)
            sys.exit(1)

    # Extract all links
    all_links = []
    for f in md_files:
        all_links.extend(extract_links(f))

    if not all_links:
        if args.format == 'json':
            print(json.dumps([]))
        else:
            print('No links found.')
        sys.exit(0)

    # Filter by type
    if args.local_only:
        all_links = [l for l in all_links if l['is_local']]
    elif args.remote_only:
        all_links = [l for l in all_links if not l['is_local']]

    # Check links
    results = []
    local_links = [l for l in all_links if l['is_local']]
    remote_links = [l for l in all_links if not l['is_local']]

    # Check local links
    for link in local_links:
        base_dir = os.path.dirname(os.path.abspath(link['file']))
        results.append(check_local_link(link, base_dir))

    # Check remote links concurrently
    if remote_links:
        with ThreadPoolExecutor(max_workers=args.concurrency) as executor:
            futures = {executor.submit(check_remote_link, l): l for l in remote_links}
            for future in as_completed(futures):
                results.append(future.result())

    # Output
    if args.format == 'json':
        output = []
        for r in results:
            output.append({
                'file': r['file'],
                'line': r['line'],
                'text': r['text'],
                'url': r['url'],
                'status': r['status'],
                'ok': r['ok']
            })
        print(json.dumps(output, indent=2))
    else:
        dead = [r for r in results if not r['ok']]
        alive = [r for r in results if r['ok']]

        for r in results:
            status = 'OK' if r['ok'] else 'DEAD'
            icon = '✓' if r['ok'] else '✗'
            print(f'  {icon} [{status}] {r["url"]}')
            if not r['ok']:
                print(f'         {r["file"]}:{r["line"]} "{r["text"]}"')
                if 'error' in r:
                    print(f'         Error: {r["error"]}')

        print(f'\nTotal: {len(results)} links ({len(alive)} ok, {len(dead)} dead)')

        if dead:
            sys.exit(2)


if __name__ == '__main__':
    main()
