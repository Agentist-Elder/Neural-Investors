#!/usr/bin/env bash
set -euo pipefail

ALLOW_DIRS_REGEX='^(src/|docs/|examples/|plans/|tests?/|README\.md$|LICENSE$|\.github/labels\.yml$)'
MAX_DIFF_BYTES="${MAX_DIFF_BYTES:-200000}"
BRANCH="${1:-llm/proposed}"
BASE="${2:-main}"
CREATE_PR="${CREATE_PR:-0}"

die() { echo "❌ $*" >&2; exit 1; }

git diff --quiet || die "Working tree has unstaged changes. Commit/stash first."
git diff --cached --quiet || die "Index has staged changes. Commit/stash first."
git rev-parse --verify "origin/$BASE" >/dev/null 2>&1 || die "Base branch origin/$BASE not found."

echo "📥 Paste a unified diff. Press Ctrl-D when done..."
tmp="$(mktemp)"; trap 'rm -f "$tmp" apply.err apply3.err' EXIT
cat > "$tmp"

[[ -s "$tmp" ]] || die "No input received."
grep -Eq '^(diff --git |--- |Index: )' "$tmp" || die "Input does not look like a unified diff."

if [ "$(wc -c < "$tmp")" -gt "$MAX_DIFF_BYTES" ]; then
  die "Diff too large (limit: ${MAX_DIFF_BYTES} bytes)."
fi

if grep -E '^(---|\+\+\+) [ab]/' "$tmp" | sed -E 's@^(---|\+\+\+) [ab]/@@' | cut -f1 -d$'\t' | grep -Ev -- "$ALLOW_DIRS_REGEX" >/dev/null; then
  echo "❌ Diff touches forbidden paths" >&2
  exit 1
fi

git fetch -q
git checkout -B "$BRANCH" "origin/$BASE" >/dev/null

if ! git apply --check "$tmp" 2>apply.err; then
  if git apply --3way --check "$tmp" 2>apply3.err; then
    git apply --3way --whitespace=fix "$tmp"
  else
    cat apply.err apply3.err >&2
    exit 1
  fi
else
  git apply --whitespace=fix "$tmp"
fi

git diff --quiet && git diff --cached --quiet && exit 0

git add -A
git -c user.name="Claude-Code-Bot" -c user.email="bot@users.noreply.github.com" commit -m "Apply LLM patch"
git push -u origin "$BRANCH" -f

echo "✅ Pushed to: https://github.com/Agentist-Elder/Neural-Investors/compare/${BRANCH}"
