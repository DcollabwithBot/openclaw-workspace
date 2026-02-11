#!/bin/bash
# cpanel.sh - cPanel UAPI wrapper script
# Usage: cpanel.sh <Module> <function> [param1=value1] [param2=value2] ...

set -euo pipefail

# Configuration
CREDS_FILE="${CPANEL_CREDS:-$HOME/.openclaw/credentials/cpanel-token}"
HOST_FILE="${CPANEL_HOST_FILE:-$HOME/.openclaw/credentials/cpanel-host}"
PORT="${CPANEL_PORT:-2083}"
TIMEOUT="${CPANEL_TIMEOUT:-30}"

# Color output (optional)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
error() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

warn() {
    echo -e "${YELLOW}Warning: $1${NC}" >&2
}

success() {
    echo -e "${GREEN}$1${NC}"
}

usage() {
    cat << EOF
Usage: cpanel.sh <Module> <function> [param1=value1] [param2=value2] ...

Examples:
  cpanel.sh Email list_pops
  cpanel.sh Quota get_quota_info
  cpanel.sh Mysql list_databases
  cpanel.sh Mysql create_database name=mydb
  cpanel.sh Fileman list_files dir=/home/username/public_html

Environment Variables:
  CPANEL_CREDS     Path to credentials file (default: ~/.openclaw/credentials/cpanel-token)
  CPANEL_HOST_FILE Path to hostname file (default: ~/.openclaw/credentials/cpanel-host)
  CPANEL_PORT      cPanel port (default: 2083)
  CPANEL_TIMEOUT   Request timeout in seconds (default: 30)

Credentials file format:
  username:APITOKEN

Hostname file format:
  hostname.example.com
EOF
    exit 1
}

# Check arguments
if [[ $# -lt 2 ]]; then
    usage
fi

MODULE="$1"
FUNCTION="$2"
shift 2

# Read credentials
if [[ ! -f "$CREDS_FILE" ]]; then
    error "Credentials file not found: $CREDS_FILE"
fi

CREDS=$(cat "$CREDS_FILE")
if [[ ! "$CREDS" =~ ^[^:]+:.+$ ]]; then
    error "Invalid credentials format. Expected: username:TOKEN"
fi

USERNAME=$(echo "$CREDS" | cut -d: -f1)
TOKEN=$(echo "$CREDS" | cut -d: -f2-)

# Read hostname
if [[ ! -f "$HOST_FILE" ]]; then
    error "Hostname file not found: $HOST_FILE"
fi

HOST=$(cat "$HOST_FILE" | tr -d '[:space:]')
if [[ -z "$HOST" ]]; then
    error "Hostname is empty in $HOST_FILE"
fi

# Build query parameters
PARAMS=""
for arg in "$@"; do
    if [[ "$arg" =~ ^([^=]+)=(.*)$ ]]; then
        KEY="${BASH_REMATCH[1]}"
        VALUE="${BASH_REMATCH[2]}"
        # URL encode the value
        VALUE=$(printf %s "$VALUE" | jq -sRr @uri)
        if [[ -z "$PARAMS" ]]; then
            PARAMS="?${KEY}=${VALUE}"
        else
            PARAMS="${PARAMS}&${KEY}=${VALUE}"
        fi
    else
        warn "Ignoring invalid parameter: $arg (expected key=value)"
    fi
done

# Build API URL
API_URL="https://${HOST}:${PORT}/execute/${MODULE}/${FUNCTION}${PARAMS}"

# Debug output (optional)
if [[ "${DEBUG:-0}" == "1" ]]; then
    echo "API URL: $API_URL" >&2
    echo "Username: $USERNAME" >&2
fi

# Make API call
RESPONSE=$(curl -s \
    --max-time "$TIMEOUT" \
    -H "Authorization: cpanel ${USERNAME}:${TOKEN}" \
    "$API_URL" 2>&1)

CURL_EXIT=$?

if [[ $CURL_EXIT -ne 0 ]]; then
    error "curl failed with exit code $CURL_EXIT. Response: $RESPONSE"
fi

# Check if response is valid JSON
if ! echo "$RESPONSE" | jq . > /dev/null 2>&1; then
    error "Invalid JSON response: $RESPONSE"
fi

# Check API status
STATUS=$(echo "$RESPONSE" | jq -r '.result.status // 0')

if [[ "$STATUS" == "0" ]]; then
    ERRORS=$(echo "$RESPONSE" | jq -r '.result.errors // "Unknown error"')
    error "API call failed: $ERRORS"
fi

# Output the result
echo "$RESPONSE" | jq -r '.result.data // .result'

exit 0
