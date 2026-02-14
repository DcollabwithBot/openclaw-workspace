#!/bin/bash
# Credential rotation check - alerts 14 days before expiry
# Scans all PROJECT.md files for credential rotation dates

set -e

WORKSPACE="/root/.openclaw/workspace"
WARN_DAYS=14
NOW=$(date +%s)
ISSUES=()

echo "Checking credential rotation status..."

# Find all PROJECT.md files
while IFS= read -r -d '' project_file; do
  # Extract credential entries with dates
  # Format expected: | Service | Purpose | Received | Next Rotation |
  
  while IFS='|' read -r service purpose received next_rotation; do
    # Skip header and empty lines
    if [[ "$service" =~ ^[[:space:]]*Service || -z "$service" ]]; then
      continue
    fi
    
    # Clean up fields
    service=$(echo "$service" | xargs)
    next_rotation=$(echo "$next_rotation" | xargs)
    
    if [ -z "$next_rotation" ] || [ "$next_rotation" = "-" ]; then
      continue
    fi
    
    # Parse rotation date (YYYY-MM-DD)
    rotation_ts=$(date -d "$next_rotation" +%s 2>/dev/null || echo "0")
    
    if [ "$rotation_ts" -eq 0 ]; then
      ISSUES+=("{\"service\":\"$service\",\"issue\":\"Invalid rotation date\",\"date\":\"$next_rotation\"}")
      continue
    fi
    
    # Calculate days until rotation
    days_until=$((($rotation_ts - $NOW) / 86400))
    
    if [ $days_until -lt 0 ]; then
      ISSUES+=("{\"service\":\"$service\",\"severity\":\"high\",\"issue\":\"Overdue rotation\",\"days_overdue\":$((- days_until))}")
    elif [ $days_until -lt $WARN_DAYS ]; then
      ISSUES+=("{\"service\":\"$service\",\"severity\":\"medium\",\"issue\":\"Rotation due soon\",\"days_until\":$days_until}")
    fi
    
  done < <(grep -E '^\|[[:space:]]*[^|]+[[:space:]]*\|' "$project_file" 2>/dev/null || true)
  
done < <(find "$WORKSPACE/projects" -name "PROJECT.md" -print0 2>/dev/null)

# Output JSON
echo "{"
echo "  \"checked_at\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
echo "  \"warn_days\": $WARN_DAYS,"
echo "  \"issues\": ["

if [ ${#ISSUES[@]} -gt 0 ]; then
  for i in "${!ISSUES[@]}"; do
    echo "    ${ISSUES[$i]}"
    if [ $i -lt $((${#ISSUES[@]} - 1)) ]; then
      echo ","
    fi
  done
else
  echo "    {\"status\":\"all_ok\"}"
fi

echo "  ]"
echo "}"

# Exit code
if [ ${#ISSUES[@]} -gt 0 ]; then
  exit 1  # Has issues
fi

exit 0
