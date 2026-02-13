#!/bin/bash
# Security check: Find credentials due for rotation

echo "🔐 Credential Rotation Check"
echo "==========================="
echo ""

# Find all PROJECT.md files
find /root/.openclaw/workspace/projects -name "PROJECT.md" -type f | while read project_file; do
    project_name=$(dirname "$project_file" | xargs basename)
    echo "📁 Project: $project_name"
    
    # Extract rotation dates (simplified - real implementation would parse markdown table)
    grep "Næste rotation" "$project_file" | while read line; do
        echo "  $line"
    done
    
    echo ""
done

echo "💡 Tip: Keys bør roteres hver 90. dag"
