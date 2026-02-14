#!/bin/bash
# Completeness check - Ensures "last 10%" is done
# Danny's ADHD guardian

set -e

PROJECT_PATH=""
CHECK_TESTS=true
CHECK_DOCS=true
CHECK_DEPLOY=true
STRICT=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --tests)
      CHECK_TESTS=true
      shift
      ;;
    --docs)
      CHECK_DOCS=true
      shift
      ;;
    --deploy)
      CHECK_DEPLOY=true
      shift
      ;;
    --strict)
      STRICT=true
      shift
      ;;
    *)
      PROJECT_PATH="$1"
      shift
      ;;
  esac
done

if [ -z "$PROJECT_PATH" ]; then
  echo "Usage: $0 <project-path> [--tests] [--docs] [--deploy] [--strict]"
  exit 1
fi

if [ ! -d "$PROJECT_PATH" ]; then
  echo "Error: '$PROJECT_PATH' is not a directory"
  exit 1
fi

SCORE=100
MISSING=()
RECOMMENDATIONS=()

# Helper: deduct points
deduct() {
  local points=$1
  SCORE=$((SCORE - points))
}

# Helper: add missing item
add_missing() {
  local item=$1
  MISSING+=("$item")
}

# Helper: add recommendation
add_recommendation() {
  local rec=$1
  if ! [[ " ${RECOMMENDATIONS[@]} " =~ " $rec " ]]; then
    RECOMMENDATIONS+=("$rec")
  fi
}

# Check 1: TODOs/FIXMEs
check_todos() {
  local todo_count=$(find "$PROJECT_PATH" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.sh" \) -exec grep -i "TODO\|FIXME" {} \; 2>/dev/null | wc -l)
  
  if [ "$todo_count" -gt 0 ]; then
    add_missing "$todo_count TODOs/FIXMEs unresolved"
    deduct $((todo_count * 3))
    add_recommendation "Resolve all TODOs or create Todoist tasks"
  fi
}

# Check 2: Tests exist
check_tests() {
  if [ "$CHECK_TESTS" = false ]; then
    return
  fi
  
  local has_tests=false
  
  # Check for test files
  if find "$PROJECT_PATH" -type f \( -name "*.test.js" -o -name "*.test.ts" -o -name "*.spec.js" -o -name "test_*.py" -o -name "*_test.go" \) | grep -q .; then
    has_tests=true
  fi
  
  # Check for test directory
  if [ -d "$PROJECT_PATH/test" ] || [ -d "$PROJECT_PATH/tests" ] || [ -d "$PROJECT_PATH/__tests__" ]; then
    has_tests=true
  fi
  
  if [ "$has_tests" = false ]; then
    add_missing "Tests not found"
    deduct 20
    add_recommendation "Add tests for main functionality"
  fi
}

# Check 3: Documentation
check_docs() {
  if [ "$CHECK_DOCS" = false ]; then
    return
  fi
  
  # Check README exists
  if [ ! -f "$PROJECT_PATH/README.md" ]; then
    add_missing "README.md missing"
    deduct 10
    add_recommendation "Create README.md with project description"
  else
    # Check README has deployment section
    if ! grep -qi "deploy\|deployment\|getting started\|installation" "$PROJECT_PATH/README.md"; then
      add_missing "README.md missing deployment/setup section"
      deduct 5
      add_recommendation "Document deployment steps in README"
    fi
  fi
}

# Check 4: Deployment readiness
check_deployment() {
  if [ "$CHECK_DEPLOY" = false ]; then
    return
  fi
  
  # Check for package.json or requirements.txt
  local has_deps=false
  if [ -f "$PROJECT_PATH/package.json" ] || [ -f "$PROJECT_PATH/requirements.txt" ] || [ -f "$PROJECT_PATH/go.mod" ] || [ -f "$PROJECT_PATH/Gemfile" ]; then
    has_deps=true
  fi
  
  if [ "$has_deps" = false ]; then
    add_missing "No dependency file found"
    deduct 5
    add_recommendation "Add dependency manifest (package.json, requirements.txt, etc)"
  fi
  
  # Check for .env.example
  if [ -f "$PROJECT_PATH/.env" ] && [ ! -f "$PROJECT_PATH/.env.example" ]; then
    add_missing ".env.example missing"
    deduct 5
    add_recommendation "Create .env.example with required variables"
  fi
}

# Check 5: Error handling
check_error_handling() {
  local total_files=$(find "$PROJECT_PATH" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.py" \) | wc -l)
  
  if [ "$total_files" -gt 0 ]; then
    local files_with_errors=$(find "$PROJECT_PATH" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.py" \) -exec grep -l "try\|catch\|except\|throw\|raise" {} \; 2>/dev/null | wc -l)
    
    if [ "$files_with_errors" -eq 0 ]; then
      add_missing "No error handling found"
      deduct 10
      add_recommendation "Add error handling (try-catch/try-except)"
    fi
  fi
}

# Check 6: Console.logs left in code
check_debug_code() {
  local console_count=$(find "$PROJECT_PATH" -type f \( -name "*.js" -o -name "*.ts" \) -exec grep -c "console\.log\|console\.debug\|console\.error" {} \; 2>/dev/null | awk '{s+=$1} END {print s}' || echo "0")
  
  if [ "$console_count" -gt 5 ]; then
    add_missing "$console_count console.log statements"
    deduct 5
    add_recommendation "Remove or replace console.logs with proper logging"
  fi
}

# Check 7: Broken references
check_broken_references() {
  # Check for import/require statements pointing to non-existent files
  local broken=0
  
  while IFS= read -r -d '' file; do
    while IFS= read -r line; do
      # Extract file path from import/require
      local ref=$(echo "$line" | grep -oP "(?<=from ['\"])[^'\"]+(?=['\"])|(?<=require\(['\"])[^'\"]+(?=['\"])")
      
      if [ -n "$ref" ] && [[ "$ref" == ./* ]] || [[ "$ref" == ../* ]]; then
        local ref_path=$(dirname "$file")/"$ref"
        
        # Add extensions if missing
        if [ ! -f "$ref_path" ]; then
          for ext in .js .ts .jsx .tsx; do
            if [ -f "${ref_path}${ext}" ]; then
              ref_path="${ref_path}${ext}"
              break
            fi
          done
        fi
        
        if [ ! -f "$ref_path" ]; then
          ((broken++))
        fi
      fi
    done < <(grep -E "^import.*from|require\(" "$file" 2>/dev/null || true)
  done < <(find "$PROJECT_PATH" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" \) -print0)
  
  if [ "$broken" -gt 0 ]; then
    add_missing "$broken broken imports/references"
    deduct $((broken * 5))
    add_recommendation "Fix broken import statements"
  fi
}

# Run checks
check_todos
check_tests
check_docs
check_deployment
check_error_handling
check_debug_code
check_broken_references

# Run vibe-check if available
VIBE_CHECK_PATH="/root/.openclaw/workspace/skills/vibe-check/vibe-check.sh"
if [ -x "$VIBE_CHECK_PATH" ]; then
  VIBE_RESULT=$("$VIBE_CHECK_PATH" "$PROJECT_PATH" 2>/dev/null || echo '{"score":0}')
  VIBE_SCORE=$(echo "$VIBE_RESULT" | grep -oP '(?<="score":\s)\d+(\.\d+)?' || echo "0")
  
  if (( $(awk "BEGIN {print ($VIBE_SCORE < 7.0)}") )); then
    add_missing "Vibe-check score too low ($VIBE_SCORE)"
    deduct 10
    add_recommendation "Fix code quality issues (run vibe-check for details)"
  fi
fi

# Ensure score doesn't go negative
if [ "$SCORE" -lt 0 ]; then
  SCORE=0
fi

# Determine if complete
COMPLETE="true"
if [ "$SCORE" -lt 90 ]; then
  COMPLETE="false"
fi

if [ "$STRICT" = true ] && [ "$SCORE" -lt 95 ]; then
  COMPLETE="false"
fi

# Build JSON output
echo "{"
echo "  \"complete\": $COMPLETE,"
echo "  \"score\": $SCORE,"
echo "  \"path\": \"$PROJECT_PATH\","
echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
echo "  \"missing\": ["

if [ ${#MISSING[@]} -gt 0 ]; then
  for i in "${!MISSING[@]}"; do
    echo "    \"${MISSING[$i]}\""
    if [ $i -lt $((${#MISSING[@]} - 1)) ]; then
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

# Exit code
if [ "$COMPLETE" = "false" ]; then
  exit 1
fi

exit 0
