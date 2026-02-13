#!/bin/bash
# Monthly memory cleanup and archiving

echo "🧹 Memory Cleanup & Archiving"
echo "============================"
echo ""

# Get current date
current_year=$(date +%Y)
current_month=$(date +%m)

# Check MEMORY.md size
word_count=$(wc -w < /root/.openclaw/workspace/memory/MEMORY.md)
token_estimate=$((word_count * 1))  # rough estimate - using 1:1 for danish/english

echo "📊 MEMORY.md size:"
echo "  Words: $word_count"
echo "  Estimated tokens: ~$token_estimate/3000"
echo ""

# If >2500 words, warn
if [ $word_count -gt 2500 ]; then
    echo "⚠️  ALERT: MEMORY.md approaching 3000 token limit"
    echo "  Action: Review for archiving"
fi

echo ""

# Archive old daily files (older than 30 days)
echo "📦 Archiving daily files..."

# Find files older than 30 days that are not already in archive
find /root/.openclaw/workspace/memory -name "20??-??-??.md" -type f -mtime +30 | while read file; do
    # Extract date from filename
    filename=$(basename "$file")
    year=$(echo $filename | cut -d'-' -f1)
    month=$(echo $filename | cut -d'-' -f2)
    
    # Create archive dir if needed
    archive_dir="/root/.openclaw/workspace/memory/archive/${year}-${month}"
    mkdir -p "$archive_dir"
    
    # Move to archive
    mv "$file" "$archive_dir/"
    echo "  📁 Moved: $filename → archive/${year}-${month}/"
done

echo ""

# Summary
echo "✅ Archive status:"
for dir in /root/.openclaw/workspace/memory/archive/*/; do
    if [ -d "$dir" ]; then
        count=$(ls -1 "$dir"/*.md 2>/dev/null | wc -l)
        echo "  $(basename $dir): $count files"
    fi
done

echo ""

# Current memory
current_count=$(ls -1 /root/.openclaw/workspace/memory/20??-??-??.md 2>/dev/null | wc -l)
echo "📂 Current daily files in memory/: $current_count"
echo ""

# Recommendation
if [ $word_count -gt 2000 ]; then
    echo "💡 Recommendation:"
    echo "  Consider archiving old entries in MEMORY.md"
    echo "  Move to: memory/archive/MEMORY-YYYY-MM.md"
fi

echo ""
echo "Cleanup complete!"
