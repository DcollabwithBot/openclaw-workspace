#!/bin/bash
# Vibe-check - Code quality detector
# Detects sloppy, untested, or incomplete code

set -e

TARGET=""
THRESHOLD=7.0

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --threshold)
      THRESHOLD="$2"
      shift 2
      ;;
    *)
      TARGET="$1"
      shift
      ;;
  esac
done

if [ -z "$TARGET" ]; then
  echo "Usage: $0 <file-or-directory> [--threshold <score>]"
  exit 1
fi

if [ ! -e "$TARGET" ]; then
  echo "Error: '$TARGET' does not exist"
  exit 1
fi

# Initialize scoring
SCORE=10.0
ISSUES=()
RECOMMENDATIONS=()

# Helper: deduct points
deduct() {
  local points=$1
  SCORE=$(awk "BEGIN {print $SCORE - $points}")
}

# Helper: add issue
add_issue() {
  local severity=$1
  local line=$2
  local issue=$3
  local suggestion=$4
  ISSUES+=("{\"severity\":\"$severity\",\"line\":$line,\"issue\":\"$issue\",\"suggestion\":\"$suggestion\"}")
}

# Helper: add recommendation
add_recommendation() {
  local rec=$1
  if ! [[ " ${RECOMMENDATIONS[@]} " =~ " $rec " ]]; then
    RECOMMENDATIONS+=("$rec")
  fi
}

# Check 1: Hardcoded secrets/keys
check_hardcoded_secrets() {
  local file=$1
  local matches=$(grep -n -E "(password|api_key|secret|token)\s*=\s*['\"][^'\"]+['\"]" "$file" 2>/dev/null || true)
  
  if [ -n "$matches" ]; then
    local count=$(echo "$matches" | wc -l)
    while IFS=: read -r line rest; do
      add_issue "high" "$line" "Hardcoded secret/key" "Move to environment variables"
    done <<< "$matches"
    deduct $(awk "BEGIN {print $count * 2.0}")
    add_recommendation "Move secrets to .env files"
  fi
}

# Check 2: TODO/FIXME markers
check_todos() {
  local file=$1
  local matches=$(grep -n -i "TODO\|FIXME\|XXX\|HACK" "$file" 2>/dev/null || true)
  
  if [ -n "$matches" ]; then
    local count=$(echo "$matches" | wc -l)
    while IFS=: read -r line rest; do
      add_issue "medium" "$line" "Unresolved TODO/FIXME" "Complete or create task"
    done <<< "$matches"
    deduct $(awk "BEGIN {print $count * 0.5}")
    add_recommendation "Resolve all TODO/FIXME comments"
  fi
}

# Check 3: Console.log in production
check_console_logs() {
  local file=$1
  
  # Only check JS/TS files
  if [[ "$file" =~ \.(js|ts|jsx|tsx)$ ]]; then
    local matches=$(grep -n "console\.log\|console\.debug" "$file" 2>/dev/null || true)
    
    if [ -n "$matches" ]; then
      local count=$(echo "$matches" | wc -l)
      while IFS=: read -r line rest; do
        add_issue "low" "$line" "Console.log in code" "Remove or use proper logging"
      done <<< "$matches"
      deduct $(awk "BEGIN {print $count * 0.3}")
      add_recommendation "Remove console.log statements"
    fi
  fi
}

# Check 4: No error handling (JS/TS/Python)
check_error_handling() {
  local file=$1
  
  # Check for async/await without try-catch
  if [[ "$file" =~ \.(js|ts|jsx|tsx)$ ]]; then
    local async_count=$(grep -c "async " "$file" 2>/dev/null || true)
    local try_count=$(grep -c "try {" "$file" 2>/dev/null || true)
    
    if [ "$async_count" -gt 0 ] && [ "$try_count" -eq 0 ]; then
      add_issue "high" "0" "Async code without try-catch" "Add error handling"
      deduct 2.0
      add_recommendation "Add try-catch blocks for async code"
    fi
  fi
  
  # Check Python
  if [[ "$file" =~ \.py$ ]]; then
    local has_code=$(grep -c "def \|class " "$file" 2>/dev/null || echo "0")
    local has_try=$(grep -c "try:" "$file" 2>/dev/null || echo "0")
    
    if [ "$has_code" -gt 3 ] && [ "$has_try" -eq 0 ]; then
      add_issue "medium" "0" "No error handling" "Add try-except blocks"
      deduct 1.5
      add_recommendation "Add error handling (try-except)"
    fi
  fi
}

# Check 5: Dangerous functions
check_dangerous_patterns() {
  local file=$1
  
  # eval/exec
  local matches=$(grep -n "eval(\|exec(\|setTimeout.*eval" "$file" 2>/dev/null || true)
  if [ -n "$matches" ]; then
    while IFS=: read -r line rest; do
      add_issue "high" "$line" "Dangerous eval/exec usage" "Use safer alternatives"
    done <<< "$matches"
    deduct 3.0
    add_recommendation "Remove eval/exec calls"
  fi
}

# Check 6: Magic numbers
check_magic_numbers() {
  local file=$1
  
  # Count standalone numbers (not in comments, not 0 or 1)
  local magic_count=$(grep -o "[^/]  *[2-9][0-9]*" "$file" 2>/dev/null | wc -l || echo "0")
  
  if [ "$magic_count" -gt 5 ]; then
    add_issue "low" "0" "Many magic numbers ($magic_count)" "Use named constants"
    deduct 0.5
    add_recommendation "Replace magic numbers with named constants"
  fi
}

# Check 7: No input validation (simple heuristic)
check_input_validation() {
  local file=$1
  
  # Look for function params without validation
  if [[ "$file" =~ \.(js|ts)$ ]]; then
    local func_count=$(grep -c "function.*(" "$file" 2>/dev/null || echo "0")
    local validation=$(grep -c "if.*==.*null\|if.*undefined\|throw new Error" "$file" 2>/dev/null || echo "0")
    
    if [ "$func_count" -gt 3 ] && [ "$validation" -eq 0 ]; then
      add_issue "medium" "0" "No apparent input validation" "Validate function parameters"
      deduct 1.0
      add_recommendation "Add input validation"
    fi
  fi
}

# Process file
process_file() {
  local file=$1
  
  # Skip binary files, node_modules, etc
  if [[ "$file" =~ node_modules|\.git|\.min\.|\.map$ ]]; then
    return
  fi
  
  # Only check code files
  if [[ ! "$file" =~ \.(js|ts|jsx|tsx|py|sh|rb|go|java|php)$ ]]; then
    return
  fi
  
  check_hardcoded_secrets "$file"
  check_todos "$file"
  check_console_logs "$file"
  check_error_handling "$file"
  check_dangerous_patterns "$file"
  check_magic_numbers "$file"
  check_input_validation "$file"
}

# Main logic
if [ -f "$TARGET" ]; then
  process_file "$TARGET"
elif [ -d "$TARGET" ]; then
  while IFS= read -r -d '' file; do
    process_file "$file"
  done < <(find "$TARGET" -type f -print0)
fi

# Ensure score doesn't go negative
if (( $(awk "BEGIN {print ($SCORE < 0)}") )); then
  SCORE=0
fi

# Build JSON output
echo "{"
echo "  \"score\": $SCORE,"
echo "  \"path\": \"$TARGET\","
echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
echo "  \"issues\": ["

if [ ${#ISSUES[@]} -gt 0 ]; then
  for i in "${!ISSUES[@]}"; do
    echo "    ${ISSUES[$i]}"
    if [ $i -lt $((${#ISSUES[@]} - 1)) ]; then
      echo ","
    fi
  done
fi

echo "  ],"
echo "  \"recommendations\": ["

if [ ${#RECOMMENDATIONS[@]} -gt 0 ]; then
  for i in "${!RECOMMENDATIONS[@]}"; do
    echo "    \"${RECOMMENDATIONS[$i]}\""
    if [ $i -lt $((${#RECOMMENDATIONS[@]} - 1)) ]; then
      echo ","
    fi
  done
fi

echo "  ]"
echo "}"

# Exit code based on threshold
if (( $(awk "BEGIN {print ($SCORE < $THRESHOLD)}") )); then
  exit 1
fi

exit 0
