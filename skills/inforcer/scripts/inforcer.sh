#!/bin/bash
#
# Inforcer API Client
# Microsoft 365 policy management for MSPs
#

set -euo pipefail

# Config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
CREDENTIALS_DIR="${HOME}/.openclaw/credentials"
TOKEN_FILE="${CREDENTIALS_DIR}/inforcer-token"
CACHE_DIR="/tmp/inforcer-cache"
CACHE_TTL=300  # 5 minutes

# API Base URL (tilpas efter Inforcer API endpoint)
API_BASE="${INFORCER_API_URL:-https://api.inforcer.com/v1}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Get API token
get_token() {
    if [[ ! -f "$TOKEN_FILE" ]]; then
        log_error "API token not found. Run:"
        log_error "  echo 'YOUR_TOKEN' > ~/.openclaw/credentials/inforcer-token"
        log_error "  chmod 600 ~/.openclaw/credentials/inforcer-token"
        exit 1
    fi
    cat "$TOKEN_FILE"
}

# API Call
api_call() {
    local endpoint="$1"
    local method="${2:-GET}"
    local data="${3:-}"
    local token
    token=$(get_token)
    
    local curl_opts=(
        -s
        -H "Authorization: Bearer ${token}"
        -H "Content-Type: application/json"
        -H "Accept: application/json"
    )
    
    if [[ "$method" == "POST" && -n "$data" ]]; then
        curl_opts+=(-d "$data")
    fi
    
    if [[ "$method" == "POST" ]]; then
        curl "${curl_opts[@]}" -X POST "${API_BASE}${endpoint}"
    else
        curl "${curl_opts[@]}" "${API_BASE}${endpoint}"
    fi
}

# Cache helpers
cache_key() {
    echo "${CACHE_DIR}/$(echo "$1" | sha256sum | cut -d' ' -f1).json"
}

get_cached() {
    local key="$1"
    local cache_file
    cache_file=$(cache_key "$key")
    
    if [[ -f "$cache_file" ]]; then
        local age=$(( $(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null) ))
        if [[ $age -lt $CACHE_TTL ]]; then
            cat "$cache_file"
            return 0
        fi
    fi
    return 1
}

set_cached() {
    local key="$1"
    local data="$2"
    local cache_file
    cache_file=$(cache_key "$key")
    
    mkdir -p "$CACHE_DIR"
    echo "$data" > "$cache_file"
}

# Clear cache
clear_cache() {
    rm -rf "$CACHE_DIR"
    log_success "Cache cleared"
}

# Format JSON output
format_output() {
    if command -v jq &> /dev/null; then
        jq '.'
    else
        cat
    fi
}

# List tenants
cmd_tenants() {
    log_info "Fetching tenants..."
    
    local cache_key="tenants"
    local response
    
    if ! response=$(get_cached "$cache_key"); then
        response=$(api_call "/tenants")
        set_cached "$cache_key" "$response"
    fi
    
    echo "$response" | format_output
}

# Get policies for tenant
cmd_policies() {
    local tenant_id="${1:-}"
    
    if [[ -z "$tenant_id" ]]; then
        log_error "Usage: $0 policies <tenant-id>"
        exit 1
    fi
    
    log_info "Fetching policies for tenant: $tenant_id"
    api_call "/tenants/${tenant_id}/policies" | format_output
}

# Get compliance status
cmd_compliance() {
    local tenant_id="${1:-}"
    
    if [[ -z "$tenant_id" ]]; then
        log_error "Usage: $0 compliance <tenant-id>"
        exit 1
    fi
    
    log_info "Fetching compliance for tenant: $tenant_id"
    api_call "/tenants/${tenant_id}/compliance" | format_output
}

# Get backup status
cmd_backups() {
    local tenant_id="${1:-}"
    
    if [[ -z "$tenant_id" ]]; then
        log_error "Usage: $0 backups <tenant-id>"
        exit 1
    fi
    
    log_info "Fetching backups for tenant: $tenant_id"
    api_call "/tenants/${tenant_id}/backups" | format_output
}

# Get alerts
cmd_alerts() {
    log_info "Fetching alerts..."
    
    local cache_key="alerts"
    local response
    
    if ! response=$(get_cached "$cache_key"); then
        response=$(api_call "/alerts")
        set_cached "$cache_key" "$response"
    fi
    
    echo "$response" | format_output
}

# Get audit log
cmd_audit() {
    local tenant_id="${1:-}"
    local days="${2:-30}"
    
    if [[ -z "$tenant_id" ]]; then
        log_error "Usage: $0 audit <tenant-id> [days]"
        exit 1
    fi
    
    log_info "Fetching audit log for tenant: $tenant_id (last ${days} days)"
    api_call "/tenants/${tenant_id}/audit?days=${days}" | format_output
}

# API Health check
cmd_status() {
    log_info "Checking API status..."
    
    local response
    response=$(api_call "/status" 2>&1) || {
        log_error "API is unreachable"
        exit 1
    }
    
    if echo "$response" | grep -q '"status".*"ok"\|"healthy"\|"up"' 2>/dev/null; then
        log_success "API is healthy"
        echo "$response" | format_output
    else
        log_warn "API returned unexpected response"
        echo "$response" | format_output
    fi
}

# Help
cmd_help() {
    cat << 'EOF'
Inforcer API Client - Microsoft 365 Policy Management

Usage: inforcer.sh <command> [args]

Commands:
  tenants                    List all tenants
  policies <tenant-id>       Get policies for tenant
  compliance <tenant-id>     Get compliance status
  backups <tenant-id>        Get backup status
  alerts                     Get active alerts
  audit <tenant-id> [days]   Get audit log (default 30 days)
  status                     Check API health
  clear-cache                Clear local cache
  help                       Show this help

Examples:
  inforcer.sh tenants
  inforcer.sh policies abc-123-def
  inforcer.sh compliance abc-123-def
  inforcer.sh alerts
  inforcer.sh audit abc-123-def 7

Cache:
  Responses are cached for 5 minutes to reduce API calls.
  Use 'clear-cache' to force fresh data.

Credentials:
  Token: ~/.openclaw/credentials/inforcer-token
EOF
}

# Main
main() {
    local cmd="${1:-help}"
    
    case "$cmd" in
        tenants)
            cmd_tenants
            ;;
        policies)
            cmd_policies "$2"
            ;;
        compliance)
            cmd_compliance "$2"
            ;;
        backups)
            cmd_backups "$2"
            ;;
        alerts)
            cmd_alerts
            ;;
        audit)
            cmd_audit "$2" "$3"
            ;;
        status)
            cmd_status
            ;;
        clear-cache)
            clear_cache
            ;;
        help|--help|-h)
            cmd_help
            ;;
        *)
            log_error "Unknown command: $cmd"
            cmd_help
            exit 1
            ;;
    esac
}

main "$@"
