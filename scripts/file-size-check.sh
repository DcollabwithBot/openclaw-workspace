#!/bin/bash
# File Size Check - Find files >100KB and suggest splitting
# Usage: ./file-size-check.sh
# Exit 0 = OK, Exit 1 = large files found

THRESHOLD_KB=100
WORKSPACE="/root/.openclaw/workspace"
EXCLUDES="*/.git/*:*/node_modules/*:*/__pycache__/*"
LARGE_FILES=()

# Find large files
while IFS= read -r file; do
  [ -z "$file" ] && continue
  size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
  size_kb=$((size / 1024))
  if [ "$size_kb" -gt "$THRESHOLD_KB" ]; then
    LARGE_FILES+=("$file:$size_kb")
  fi
done < <(find "$WORKSPACE" -type f -size +${THRESHOLD_KB}k 2>/dev/null | grep -vE '(\.git/|node_modules/|__pycache__/)')

if [ ${#LARGE_FILES[@]} -eq 0 ]; then
  echo "✅ File size check: All files under ${THRESHOLD_KB}KB"
  exit 0
else
  echo "⚠️  FILE SIZE CHECK - Potential Bloat Detected"
  echo "Files exceeding ${THRESHOLD_KB}KB:"
  echo ""
  
  for item in "${LARGE_FILES[@]}"; do
    file="${item%:*}"
    kb="${item#*:}"
    mb=$(awk "BEGIN {printf \"%.2f\", $kb/1024}")
    echo "  📄 ${file#$WORKSPACE/}"
    echo "     Size: ${kb}KB (${mb}MB)"
    
    # Suggestion based on file type
    if [[ "$file" == *.md ]]; then
      echo "     💡 Suggest: Split into sections (YYYY-MM-DD-*.md)"
    elif [[ "$file" == *.json ]]; then
      echo "     💡 Suggest: Archive old entries or split by month"
    elif [[ "$file" == *.log ]]; then
      echo "     💡 Suggest: Rotate logs (logrotate)"
    else
      echo "     💡 Suggest: Review for unnecessary inclusion"
    fi
    echo ""
  done
  
  exit 1
fi
