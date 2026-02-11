#!/bin/bash
#
# Installer Git Security hooks
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Find git directory
find_git_dir() {
    local dir="${1:-$(pwd)}"
    if [[ -d "$dir/.git" ]]; then
        echo "$dir/.git"
        return 0
    fi
    # Check if we're in a git worktree
    if [[ -f "$dir/.git" ]]; then
        local gitfile
        gitfile=$(cat "$dir/.git" | sed 's/gitdir: //')
        if [[ -d "$gitfile" ]]; then
            echo "$gitfile"
            return 0
        fi
    fi
    return 1
}

# Install hooks in a repo
install_hooks() {
    local repo="${1:-$(pwd)}"
    local git_dir
    
    git_dir=$(find_git_dir "$repo") || {
        log_error "Ikke et git repo: $repo"
        return 1
    }
    
    local hooks_dir="$git_dir/hooks"
    mkdir -p "$hooks_dir"
    
    log_info "Installerer hooks i: $repo"
    
    # Install pre-commit
    ln -sf "$SCRIPT_DIR/pre-commit.sh" "$hooks_dir/pre-commit" && \
        log_success "pre-commit hook installeret"
    
    # Install pre-push
    ln -sf "$SCRIPT_DIR/pre-push.sh" "$hooks_dir/pre-push" && \
        log_success "pre-push hook installeret"
    
    # Create .gitsecurityignore if not exists
    if [[ ! -f "$repo/.gitsecurityignore" ]]; then
        cat > "$repo/.gitsecurityignore" << 'EOF'
# Git Security Ignore File
# Tilføj filer der skal ignoreres af security scanner

# Eksempler:
# src/test/fixtures/mock-keys.txt
# docs/examples/
EOF
        log_success ".gitsecurityignore oprettet"
    fi
    
    echo ""
    log_success "Hooks installeret i: $repo"
    echo ""
    echo "For at deaktivere midlertidigt:"
    echo "  SKIP_GIT_SECURITY=1 git commit"
}

# Install globally
install_global() {
    local global_hooks="${HOME}/.git-hooks"
    mkdir -p "$global_hooks"
    
    log_info "Installerer globale hooks i: $global_hooks"
    
    ln -sf "$SCRIPT_DIR/pre-commit.sh" "$global_hooks/pre-commit"
    ln -sf "$SCRIPT_DIR/pre-push.sh" "$global_hooks/pre-push"
    
    log_success "Globale hooks installeret"
    echo ""
    echo "For at aktivere globale hooks, kør:"
    echo "  git config --global core.hooksPath ${global_hooks}"
}

# Check existing hooks
check_existing() {
    local repo="${1:-$(pwd)}"
    local git_dir
    
    git_dir=$(find_git_dir "$repo") || return 1
    local hooks_dir="$git_dir/hooks"
    
    if [[ -f "$hooks_dir/pre-commit" && ! -L "$hooks_dir/pre-commit" ]]; then
        log_warn "Eksisterende pre-commit hook fundet (ikke symlink)"
        echo "Backup: $hooks_dir/pre-commit.backup"
        cp "$hooks_dir/pre-commit" "$hooks_dir/pre-commit.backup"
    fi
    
    if [[ -f "$hooks_dir/pre-push" && ! -L "$hooks_dir/pre-push" ]]; then
        log_warn "Eksisterende pre-push hook fundet (ikke symlink)"
        echo "Backup: $hooks_dir/pre-push.backup"
        cp "$hooks_dir/pre-push" "$hooks_dir/pre-push.backup"
    fi
}

# Main
main() {
    local target="${1:-$(pwd)}"
    
    if [[ "$target" == "--global" ]]; then
        install_global
        return 0
    fi
    
    if [[ "$target" == "--help" || "$target" == "-h" ]]; then
        echo "Usage: $0 [--global | path/to/repo]"
        echo ""
        echo "Options:"
        echo "  --global    Installér globale hooks"
        echo "  --help      Vis denne hjælp"
        echo ""
        echo "Eksempler:"
        echo "  $0                          # Installer i nuværende repo"
        echo "  $0 /path/to/repo            # Installer i specifikt repo"
        echo "  $0 --global                 # Installer globalt"
        return 0
    fi
    
    # Resolve path
    if [[ -d "$target" ]]; then
        target=$(cd "$target" && pwd)
    fi
    
    check_existing "$target"
    install_hooks "$target"
}

main "$@"
