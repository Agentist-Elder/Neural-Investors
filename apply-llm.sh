#!/usr/bin/env bash
set -euo pipefail

# ========= Config (edit to taste) =========
# Only allow changes in these paths (regex against file headers in the diff)
ALLOW_DIRS_REGEX='^(src/|docs/|examples/|plans/|tests?/|README\.md$|LICENSE$|\.github/labels\.yml$)'

# Max diff size in bytes (guards against giant/binary pastes)
MAX_DIFF_BYTES="${MAX_DIFF_BYTES:-200000}"

# Branch to create/update (1st arg) and base branch (2nd arg or auto-detect)
BRANCH="${1:-llm/proposed}"
BASE="${2:-$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||' || echo main)}"

# If set to 1 and `gh` is authenticated, auto-open a PR
CREATE_PR="${CREATE_PR:-0}"
# =========================================

die() { echo "❌ $*" >&2; exit 1; }

# Ensure clean working tree
git diff --quiet || die "Working tree has unstaged changes. Commit/stash first."
git diff --cached --quiet || die "Index has staged changes. Commit/stash first."

# Ensure base exists
git rev-parse --verify "origin/$BASE" >/dev/null 2>&1 || die "Base branch origin/$BASE not found."

echo "📥 Paste a unified diff (e.g., a ```diff block). Press Ctrl-D when done..."
tmp="$(mktemp)"; trap 'rm -f "$tmp" apply.err apply3.err' EXIT
cat > "$tmp"

# Basic sanity
[[ -s "$tmp" ]] || die "No input received."
grep -Eq '^(diff --git |--- |Index: )' "$tmp" || die "Input does not look like a unified diff."

# Size check
if [ "$(wc -c < "$tmp")" -gt "$MAX_DIFF_BYTES" ]; then
  die "Diff too large (limit: ${MAX_DIFF_BYTES} bytes). Split into smaller chunks."
fi

# Allow-list check: extract file headers, tolerate spaces/tabs
# Matches '+++ b/path<TAB>...' and '--- a/path<TAB>...'
if grep -E '^(---|\+\+\+) [ab]/' "$tmp" \
  | sed -E 's@^(---|\+\+\+) [ab]/@@' \
  | cut -f1 -d$'\t' \
  | grep -Ev -- "$ALLOW_DIRS_REGEX" >/dev/null
then
  echo "❌ Diff touches paths outside allowed areas:" >&2
  grep -E '^(---|\+\+\+) [ab]/' "$tmp" \
    | sed -E 's@^(---|\+\+\+) [ab]/@@' \
    | cut -f1 -d$'\t' \
    | grep -Ev -- "$ALLOW_DIRS_REGEX" \
    | sed 's/^/ • /' >&2
  exit 1
fi

echo "🔄 Preparing branch '$BRANCH' from origin/$BASE ..."
git fetch -q
git checkout -B "$BRANCH" "origin/$BASE" >/dev/null

echo "🧪 Dry-run apply check ..."
if ! git apply --check "$tmp" 2>apply.err; then
  echo "ℹ️ Dry-run failed. Trying 3-way merge apply..." >&2
  if git apply --3way --check "$tmp" 2>apply3.err; then
    rm -f apply.err apply3.err
    echo "✅ 3-way apply will work; proceeding..."
    git apply --3way --whitespace=fix "$tmp"
  else
    echo "❌ Patch does not apply cleanly. Details:" >&2
    cat apply.err apply3.err 2>/dev/null >&2
    exit 1
  fi
else
  rm -f apply.err
  echo "✅ Dry-run OK; applying..."
  git apply --whitespace=fix "$tmp"
fi

# No-op check
if git diff --quiet && git diff --cached --quiet; then
  echo "ℹ️ No changes after apply (empty or already applied)."
  exit 0
fi

git add -A
git -c user.name="Claude-Code-Bot" \
    -c user.email="bot@users.noreply.github.com" \
    commit -m "Apply LLM patch"

echo "📤 Pushing '$BRANCH' ..."
git push -u origin "$BRANCH" -f

# Optional PR creation
if [ "$CREATE_PR" = "1" ] && command -v gh >/dev/null 2>&1; then
  echo "📝 Creating PR ..."
  if gh pr create --fill --base "$BASE" --head "$BRANCH" >/dev/null 2>&1; then
    gh pr view --web >/dev/null 2>&1 || true
    echo "🔗 PR opened (attempted to open in browser)."
  else
    echo "ℹ️ Could not auto-create PR (is gh authed? 'gh auth login')."
  fi
fi

REPO_URL="$(git config --get remote.origin.url | sed -E 's/\.git$//; s#^git@github.com:#https://github.com/#; s#^https://[^@]+@#https://#')"
echo "📄 Files changed:"
git diff --name-only HEAD~1..HEAD | sed 's/^/ • /'
echo "✅ Done. Review here:"
echo "🔗 ${REPO_URL}/compare/${BRANCH}?expand=1"
