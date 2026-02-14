#!/bin/bash
# Secret Scanner - Detects API keys and credentials
# Usage: ./secret-scan.sh [directory]
# Exit 0 = clean, Exit 1 = secrets found

DIR="${1:-/root/.openclaw/workspace}"
OUTPUT_FILE="/tmp/secret-scan-$(date +%s).json"

# Regex patterns for common secrets
PATTERNS=(
  'sk-[a-zA-Z0-9]{20,}'           # OpenAI/Anthropic keys
  'ghp_[a-zA-Z0-9]{36}'           # GitHub personal tokens
  'gho_[a-zA-Z0-9]{36}'           # GitHub OAuth tokens
  'AKIA[0-9A-Z]{16}'              # AWS Access Key ID
  '[0-9a-zA-Z/+]{40}'             # AWS Secret Key (base64-like)
  'ya29\.[a-zA-Z0-9_-]+'          # Google OAuth tokens
  'pat-[a-zA-Z0-9]{22}'           # DigitalOcean tokens
  'Bearer[[:space:]]+[a-zA-Z0-9_-]+'  # Generic bearer tokens
  'api[_-]?key[[:space:]]*=[[:space:]]*[a-zA-Z0-9]{16,}'  # Generic API keys
  'password[[:space:]]*=[[:space:]]*[^[:space:]]{8,}'     # Passwords
)

echo "{\"scan_time\": \"$(date -Iseconds)\", \"directory\": \"$DIR\", \"secrets_found\": false, \"matches\": []}" > "$OUTPUT_FILE"

FOUND=0
MATCHES=""

for pattern in "${PATTERNS[@]}"; do
  while IFS=: read -r file line match; do
    if [ -n "$file" ]; then
      FOUND=$((FOUND + 1))
      MATCH="{\"file\": \"$file\", \"line\": $line, \"pattern\": \"${pattern//\/\\/}\", \"preview\": \"$(echo "$match" | head -c 50 | sed 's/"/\\"/g')\"}"
      if [ -n "$MATCHES" ]; then MATCHES="$MATCHES,"; fi
      MATCHES="$MATCHES$MATCH"
    fi
  done < <(grep -rnE "$pattern" "$DIR" --include="*" 2>/dev/null | head -20)
done

if [ "$FOUND" -gt 0 ]; then
  echo "{\"scan_time\": \"$(date -Iseconds)\", \"directory\": \"$DIR\", \"secrets_found\": true, \"count\": $FOUND, \"matches\": [$MATCHES]}" > "$OUTPUT_FILE"
  cat "$OUTPUT_FILE"
  exit 1
else
  cat "$OUTPUT_FILE"
  exit 0
fi
