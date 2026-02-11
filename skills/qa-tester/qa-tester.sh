#!/bin/bash
# qa-tester.sh - Website testing med Playwright
# Usage: qa-tester.sh <url> [test-type]

URL="${1:-}"
TEST_TYPE="${2:-visual}"
OUTPUT_DIR="/root/.openclaw/workspace/test-results"
mkdir -p "$OUTPUT_DIR"

if [[ -z "$URL" ]]; then
  echo '{"error": "URL required"}'
  exit 1
fi

echo "Starting $TEST_TYPE test for $URL..."

case "$TEST_TYPE" in
  visual)
    # Screenshot + basic checks
    npx playwright-core chromium --headless --screenshot="$OUTPUT_DIR/screenshot-$(date +%s).png" --viewport-size=1920,1080 "$URL" 2>&1
    echo "{\"type\": \"visual\", \"url\": \"$URL\", \"screenshot\": \"saved\", \"timestamp\": $(date +%s)}"
    ;;
    
  lighthouse)
    # Performance test
    npx lighthouse "$URL" --output=json --output-path="$OUTPUT_DIR/lighthouse-$(date +%s).json" --chrome-flags="--headless --no-sandbox" 2>&1 | tail -5
    echo "{\"type\": \"lighthouse\", \"url\": \"$URL\", \"report\": \"saved\"}"
    ;;
    
  links)
    # Check for broken links
    curl -s "$URL" | grep -oE 'href="[^"]+"' | sed 's/href="//;s/"$//' | while read link; do
      if [[ "$link" == http* ]]; then
        status=$(curl -s -o /dev/null -w "%{http_code}" "$link")
        echo "{\"link\": \"$link\", \"status\": $status}"
      fi
    done
    ;;
    
  *)
    echo '{"error": "Unknown test type. Use: visual, lighthouse, links"}'
    exit 1
    ;;
esac