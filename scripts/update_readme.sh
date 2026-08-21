#!/usr/bin/env bash
set -euo pipefail

# Script: scripts/update_readme.sh
# Purpose: Convert index.html at repo root to README.md (HTML -> Markdown)
# Usage:
#   ./scripts/update_readme.sh
# In GitHub Actions this runs from the repository root by default.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SRC="$REPO_ROOT/index.html"
DST="$REPO_ROOT/README.md"

if [ ! -f "$SRC" ]; then
  echo "Error: $SRC not found" >&2
  exit 2
fi

# Try conversion tools in order: pandoc -> npx turndown-cli -> python markdownify

convert_with_pandoc() {
  if command -v pandoc >/dev/null 2>&1; then
    echo "Using pandoc to convert HTML -> Markdown"
    # GitHub-flavored Markdown, keep wrapping off and use ATX headers
    pandoc -f html -t gfm --wrap=none --atx-headers "$SRC" -o "$DST"
    echo "Converted $SRC -> $DST (pandoc)"
    return 0
  fi
  return 1
}

convert_with_turndown() {
  if command -v npx >/dev/null 2>&1; then
    echo "Using npx turndown-cli to convert HTML -> Markdown"
    # npx will install turndown-cli if not present; -y prevents prompts on some setups
    if npx -y turndown-cli < "$SRC" > "$DST"; then
      echo "Converted $SRC -> $DST (turndown-cli)"
      return 0
    fi
  fi
  return 1
}

convert_with_python() {
  if command -v python3 >/dev/null 2>&1; then
    echo "Using python3 + markdownify to convert HTML -> Markdown"
    python3 - "$SRC" "$DST" <<'PY'
import sys
import io
from pathlib import Path
p = Path(sys.argv[1])
q = Path(sys.argv[2])
html = p.read_text(encoding='utf-8')

# try to import required libs, install if missing
try:
    from bs4 import BeautifulSoup
except Exception:
    import subprocess
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'beautifulsoup4'])
    from bs4 import BeautifulSoup

try:
    from markdownify import markdownify as md
except Exception:
    import subprocess
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'markdownify'])
    from markdownify import markdownify as md

soup = BeautifulSoup(html, 'html.parser')
body = soup.body or soup
for t in body.select('script, style'):
    t.decompose()

# Convert only the body fragment to markdown
md_text = md(str(body), heading_style='ATX')
q.write_text(md_text, encoding='utf-8')
print(f'Converted {p} -> {q} (python markdownify)')
PY
    if [ $? -eq 0 ]; then
      return 0
    fi
  fi
  return 1
}

# Run converters
if convert_with_pandoc; then
  exit 0
fi

if convert_with_turndown; then
  exit 0
fi

if convert_with_python "$SRC" "$DST"; then
  exit 0
fi

# If all converters failed, fallback to copying the raw HTML but warn
echo "Warning: no HTML->Markdown converter available (pandoc, npx, python3). Copying raw HTML to README.md instead." >&2
cp -f "$SRC" "$DST"
exit 0
