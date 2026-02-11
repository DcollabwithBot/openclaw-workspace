#!/bin/bash
#
# Git Security Scanner - Simplified
# Detekterer secrets, credentials og API keys
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Counters
CRITICAL=0
HIGH=0
MEDIUM=0
LOW=0

# Find repo root
find_repo_root() {
    local dir="${1:-$(pwd)}"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/.git" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

# Scan a file
scan_file() {
    local file="$1"
    local rel_path="${file#$REPO_ROOT/}"
    
    # Skip binary files
    if file "$file" 2>/dev/null | grep -qE "binary|executable|image|audio|video"; then
        return 0
    fi
    
    # Skip if in .gitsecurityignore
    if [[ -f "$REPO_ROOT/.gitsecurityignore" ]]; then
        if grep -qFx "$rel_path" "$REPO_ROOT/.gitsecurityignore" 2>/dev/null; then
            return 0
        fi
    fi
    
    local content
    content=$(cat "$file" 2>/dev/null || true)
    [[ -z "$content" ]] && return 0
    
    # Critical: Private keys
    if echo "$content" | grep -qE '-----BEGIN.*PRIVATE KEY-----' 2>/dev/null; then
        echo "🔴 CRITICAL: $rel_path (Private key)"
        CRITICAL=$((CRITICAL + 1))
        return
    fi
    
    # Critical: AWS keys
    if echo "$content" | grep -qE 'AKIA[0-9A-Z]{16}' 2>/dev/null; then
        echo "🔴 CRITICAL: $rel_path (AWS key)"
        CRITICAL=$((CRITICAL + 1))
        return
    fi
    
    # High: GitHub PAT
    if echo "$content" | grep -qE 'ghp_[a-zA-Z0-9]{36}' 2>/dev/null; then
        echo "🟠 HIGH: $rel_path (GitHub token)"
        HIGH=$((HIGH + 1))
        return
    fi
    
    # High: OpenAI key
    if echo "$content" | grep -qE 'sk-[a-zA-Z0-9]{48}' 2>/dev/null; then
        echo "🟠 HIGH: $rel_path (API key)"
        HIGH=$((HIGH + 1))
        return
    fi
    
    # Medium: Bearer tokens
    if echo "$content" | grep -qiE 'bearer\s+[a-zA-Z0-9]{20,}' 2>/dev/null; then
        echo "🟡 MEDIUM: $rel_path (Bearer token)"
        MEDIUM=$((MEDIUM + 1))
        return
    fi
    
    # Medium: Password in code (simplified check)
    if echo "$content" | grep -qi "password" 2>/dev/null | grep -qE "=\s*['\"][^'\"]{8,}['\"]" 2>/dev/null; then
        echo "🟡 MEDIUM: $rel_path (Hardcoded password)"
        MEDIUM=$((MEDIUM + 1))
        return
    fi
    
    # Low: .env file
    if [[ "$(basename "$file")" == .env* ]]; then
        echo "🔵 LOW: $rel_path (.env file in git)"
        LOW=$((LOW + 1))
        return
    fi
}

# Check .gitignore
check_gitignore() {
    local repo="$1"
    local gitignore="$repo/.gitignore"
    
    log_info "Checking .gitignore..."
    
    local missing=()
    local patterns="\.env \.env\.\* \*\.pem \*\.key credentials/ .openclaw/credentials/"
    
    for pattern in $patterns; do
        if ! grep -qE "^${pattern}$" "$gitignore" 2>/dev/null; then
            missing+=("$pattern")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "🟡 MEDIUM: .gitignore missing:"
        printf '    - %s\n' "${missing[@]}"
        MEDIUM=$((MEDIUM + 1))
    else
        log_success ".gitignore looks good"
    fi
}

# Scan staged files
scan_staged() {
    local repo="${1:-$(pwd)}"
    REPO_ROOT=$(find_repo_root "$repo") || { log_error "Not a git repo"; exit 1; }
    
    log_info "Scanning staged files..."
    
    local staged_files
    staged_files=$(cd "$REPO_ROOT" && git diff --cached --name-only --diff-filter=ACM 2>/dev/null || true)
    
    if [[ -z "$staged_files" ]]; then
        log_warn "No staged files"
        return 0
    fi
    
    echo ""
    echo "🔍 Scanning $(echo "$staged_files" | wc -l) staged files..."
    echo ""
    
    while IFS= read -r file; do
        [[ -f "$REPO_ROOT/$file" ]] && scan_file "$REPO_ROOT/$file"
    done <<< "$staged_files"
}

# Full repo scan
scan_repo() {
    local repo="${1:-$(pwd)}"
    REPO_ROOT=$(find_repo_root "$repo") || { log_error "Not a git repo: $repo"; exit 1; }
    
    echo ""
    echo "========================================"
    echo "🔒 Git Security Scan"
    echo "========================================"
    echo "Repo: $REPO_ROOT"
    echo ""
    
    check_gitignore "$REPO_ROOT"
    echo ""
    
    log_info "Scanning files..."
    echo ""
    
    local count=0
    while IFS= read -r -d '' file; do
        # Skip excluded dirs
        if [[ "$file" == *"/node_modules/"* ]] || [[ "$file" == *"/\.git/"* ]] || \
           [[ "$file" == *"/dist/"* ]] || [[ "$file" == *"/build/"* ]] || \
           [[ "$file" == *"/.next/"* ]] || [[ "$file" == *"/vendor/"* ]]; then
            continue
        fi
        
        scan_file "$file"
        count=$((count + 1))
        if [[ $((count % 100)) -eq 0 ]]; then
            echo "  Scanned $count files..."
        fi
    done < <(find "$REPO_ROOT" -type f -print0 2>/dev/null | head -z -n 1000)
    
    echo ""
    echo "========================================"
    echo "📊 Results"
    echo "========================================"
    echo "🔴 Critical: $CRITICAL"
    echo "🟠 High: $HIGH"
    echo "🟡 Medium: $MEDIUM"
    echo "🔵 Low: $LOW"
    echo ""
    echo "📁 Files scanned: $count"
    echo "========================================"
    
    if [[ $CRITICAL -gt 0 ]]; then
        log_error "Critical security issues found!"
        exit 2
    elif [[ $HIGH -gt 0 ]]; then
        log_warn "High security risks found"
        exit 1
    else
        log_success "No critical security issues!"
        exit 0
    fi
}

# Main
main() {
    local cmd="${1:-scan}"
    local target="${2:-$(pwd)}"
    
    case "$cmd" in
        scan)
            scan_repo "$target"
            ;;
        staged|pre-commit)
            scan_staged "$target"
            ;;
        check-gitignore)
            REPO_ROOT=$(find_repo_root "${target:-$(pwd)}") || { log_error "Not a git repo"; exit 1; }
            check_gitignore "$REPO_ROOT"
            ;;
        *)
            echo "Usage: $0 {scan|staged|check-gitignore} [path]"
            exit 1
            ;;
    esac
}

main "$@"
