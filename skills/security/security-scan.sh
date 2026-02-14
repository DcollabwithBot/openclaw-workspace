#!/bin/bash
# Security scan script - Bent's expertise as code
# Usage: ./security-scan.sh --target [path] --level [basic|deep]

set -e

TARGET=""
LEVEL="basic"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --target)
      TARGET="$2"
      shift 2
      ;;
    --level)
      LEVEL="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [ -z "$TARGET" ]; then
  echo "Error: --target required"
  exit 1
fi

if [ ! -e "$TARGET" ]; then
  echo "Error: Target '$TARGET' does not exist"
  exit 1
fi

# Initialize results
ISSUES=()
SCORE=10.0

# Check 1: Hardcoded secrets
echo "Checking for hardcoded secrets..."
SECRETS=$(grep -r -E "(sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{36}|AKIA[0-9A-Z]{16}|password\s*=|api_key\s*=)" "$TARGET" 2>/dev/null || true)
if [ -n "$SECRETS" ]; then
  ISSUES+=('{"severity":"high","issue":"Hardcoded secrets found","details":"'"$(echo "$SECRETS" | head -3 | tr '\n' ' ')"'"}')
  SCORE=$(awk "BEGIN {print $SCORE - 3.0}")
fi

# Check 2: Insecure file permissions
echo "Checking file permissions..."
WORLD_WRITABLE=$(find "$TARGET" -type f -perm -002 2>/dev/null || true)
if [ -n "$WORLD_WRITABLE" ]; then
  ISSUES+=('{"severity":"medium","issue":"World-writable files found","count":'$(echo "$WORLD_WRITABLE" | wc -l)'}')
  SCORE=$(awk "BEGIN {print $SCORE - 1.5}")
fi

# Check 3: Executable configs
EXEC_CONFIGS=$(find "$TARGET" -type f \( -name "*.json" -o -name "*.yaml" -o -name "*.yml" -o -name "*.env" \) -perm -111 2>/dev/null || true)
if [ -n "$EXEC_CONFIGS" ]; then
  ISSUES+=('{"severity":"low","issue":"Executable config files","count":'$(echo "$EXEC_CONFIGS" | wc -l)'}')
  SCORE=$(awk "BEGIN {print $SCORE - 0.5}")
fi

# Check 4: eval/exec of user input (dangerous)
if [ "$LEVEL" = "deep" ]; then
  echo "Deep scan: Checking for eval/exec patterns..."
  DANGEROUS=$(grep -r -E "(eval\(|exec\(|os\.system\(|subprocess\.call\(.*input)" "$TARGET" 2>/dev/null || true)
  if [ -n "$DANGEROUS" ]; then
    ISSUES+=('{"severity":"high","issue":"Dangerous eval/exec found","details":"'"$(echo "$DANGEROUS" | head -2 | tr '\n' ' ')"'"}')
    SCORE=$(awk "BEGIN {print $SCORE - 2.0}")
  fi
fi

# Check 5: TODO/FIXME security markers
SECURITY_TODOS=$(grep -r -i "TODO.*security\|FIXME.*security\|XXX.*security" "$TARGET" 2>/dev/null || true)
if [ -n "$SECURITY_TODOS" ]; then
  ISSUES+=('{"severity":"medium","issue":"Unresolved security TODOs","count":'$(echo "$SECURITY_TODOS" | wc -l)'}')
  SCORE=$(awk "BEGIN {print $SCORE - 1.0}")
fi

# Ensure score doesn't go negative
if (( $(awk "BEGIN {print ($SCORE < 0)}") )); then
  SCORE=0
fi

# Output JSON report
echo "{"
echo "  \"score\": $SCORE,"
echo "  \"level\": \"$LEVEL\","
echo "  \"target\": \"$TARGET\","
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
echo "  ]"
echo "}"

# Exit code based on score
if (( $(awk "BEGIN {print ($SCORE < 7.0)}") )); then
  exit 1  # Failed security scan
fi

exit 0
