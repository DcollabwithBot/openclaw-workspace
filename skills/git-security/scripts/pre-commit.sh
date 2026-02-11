#!/bin/bash
#
# Pre-commit hook for Git Security
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🔒 Git Security Pre-commit Hook"
echo "================================"
echo ""

# Check if we should skip
if [[ -n "${SKIP_GIT_SECURITY:-}" ]]; then
    echo "⚠️  SKIP_GIT_SECURITY sat - springer over"
    exit 0
fi

# Run staged scan
if "$SCRIPT_DIR/scan.sh" staged; then
    exit 0
else
    exit_code=$?
    echo ""
    echo "${RED}=================================${NC}"
    echo "${RED}❌ Commit afbrudt!${NC}"
    echo "${RED}=================================${NC}"
    echo ""
    echo "Fik problemer? Du kan:"
    echo "  1. Ret problemerne"
    echo "  2. Brug --no-verify (ikke anbefalet)"
    echo "  3. Tilføj til .gitsecurityignore"
    echo ""
    exit $exit_code
fi
