#!/bin/bash

# apply-llm.sh - Apply unified diffs from LLM output
# Usage: bash apply-llm.sh

set -e

echo "📥 Paste a unified diff. Press Ctrl-D when done..."
echo ""

# Read the entire diff into a temporary file
TEMP_DIFF=$(mktemp)
trap "rm -f $TEMP_DIFF" EXIT

cat > "$TEMP_DIFF"

# Check if diff is empty
if [ ! -s "$TEMP_DIFF" ]; then
    echo "❌ Error: No diff provided"
    exit 1
fi

echo ""
echo "📋 Diff received. Applying..."
echo ""

# Apply the patch
if patch -p1 < "$TEMP_DIFF"; then
    # Clean up .orig backup files created by patch
    find . -name "*.orig" -type f -delete

    echo ""
    echo "✅ Patch applied successfully!"
    echo ""
    echo "📊 Changes made:"
    git diff --stat
    echo ""
    echo "🔍 Detailed changes:"
    git diff
else
    echo ""
    echo "❌ Failed to apply patch"
    echo ""
    echo "Patch content:"
    cat "$TEMP_DIFF"
    exit 1
fi
