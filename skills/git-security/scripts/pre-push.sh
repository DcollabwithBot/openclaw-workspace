#!/bin/bash
#
# Pre-push hook for Git Security
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "🔒 Git Security Pre-push Hook"
echo "=============================="
echo ""

# Check if we should skip
if [[ -n "${SKIP_GIT_SECURITY:-}" ]]; then
    echo "⚠️  SKIP_GIT_SECURITY sat - springer over"
    exit 0
fi

# Get commits to be pushed
echo "📋 Commits der pushes:"
git log --oneline --graph @{upstream}..HEAD 2>/dev/null || git log --oneline -5
echo ""

# Run full scan on staged files (which includes commits)
if "$SCRIPT_DIR/scan.sh" staged; then
    echo ""
    echo "${GREEN}✅ Sikkerhedscheck bestået!${NC}"
    echo ""
    
    # Extra check: Look for new .env files in commits
    env_files=$(git diff --cached --name-only --diff-filter=A | grep -E '\.env' || true)
    if [[ -n "$env_files" ]]; then
        echo "${YELLOW}⚠️  ADVARSEL: Nye .env filer tilføjet:${NC}"
        echo "$env_files"
        echo ""
        read -p "Fortsæt alligevel? (ja/nej) " -n 3 -r
        echo
        if [[ ! $REPLY =~ ^[Jj]a$ ]]; then
            echo "❌ Push afbrudt"
            exit 1
        fi
    fi
    
    exit 0
else
    exit_code=$?
    echo ""
    echo "${RED}=================================${NC}"
    echo "${RED}❌ Push afbrudt!${NC}"
    echo "${RED}=================================${NC}"
    echo ""
    echo "Fik problemer? Du kan:"
    echo "  1. Ret problemerne og commit igen"
    echo "  2. Brug --no-verify (ikke anbefalet)"
    echo ""
    exit $exit_code
fi
