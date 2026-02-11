#!/usr/bin/env bash
set -euo pipefail

# GitHub Integration for OpenClaw
# Account: dspammails-rgb

GITHUB_TOKEN="${GITHUB_API_TOKEN:-$(cat ~/.openclaw/credentials/github 2>/dev/null || echo '')}"
API_BASE="https://api.github.com"

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo '{"error": "GITHUB_API_TOKEN not set and ~/.openclaw/credentials/github not found"}' >&2
  exit 1
fi

# Helper: API call
api() {
  local method="$1"
  local endpoint="$2"
  shift 2
  
  curl -sf -X "$method" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "$API_BASE$endpoint" \
    "$@"
}

case "${1:-}" in
  list_repos)
    OWNER="${2:-$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/user | jq -r '.login')}"
    api GET "/users/$OWNER/repos" | jq -r '.[].full_name'
    ;;
    
  clone)
    REPO="$2"
    DEST="${3:-workspace/repos/$(basename $REPO)}"
    
    mkdir -p "$DEST"
    git clone "https://dspammails-rgb:$GITHUB_TOKEN@github.com/$REPO.git" "$DEST"
    echo "{\"status\": \"cloned\", \"repo\": \"$REPO\", \"path\": \"$DEST\"}"
    ;;
    
  commit)
    REPO_PATH="$2"
    MESSAGE="$3"
    FILES="${4:-.}"
    PUSH="${5:-true}"
    
    cd "$REPO_PATH"
    
    # Configure git if not already set
    git config user.name "dspammails-rgb" 2>/dev/null || true
    git config user.email "dspammails-rgb@users.noreply.github.com" 2>/dev/null || true
    
    # Stage files
    if [[ "$FILES" == "." ]]; then
      git add .
    else
      git add $FILES
    fi
    
    # Commit
    git commit -m "$MESSAGE"
    
    # Push if requested
    if [[ "$PUSH" == "true" ]]; then
      git push
    fi
    
    echo "{\"status\": \"committed\", \"message\": \"$MESSAGE\"}"
    ;;
    
  create_pr)
    REPO="$2"
    TITLE="$3"
    BODY="${4:-}"
    HEAD="$5"
    BASE="${6:-main}"
    
    PAYLOAD="{\"title\": \"$TITLE\", \"head\": \"$HEAD\", \"base\": \"$BASE\""
    if [[ -n "$BODY" ]]; then
      PAYLOAD="$PAYLOAD, \"body\": \"$BODY\""
    fi
    PAYLOAD="$PAYLOAD}"
    
    api POST "/repos/$REPO/pulls" -d "$PAYLOAD"
    ;;
    
  create_issue)
    REPO="$2"
    TITLE="$3"
    BODY="${4:-}"
    LABELS="${5:-}"
    
    PAYLOAD="{\"title\": \"$TITLE\""
    if [[ -n "$BODY" ]]; then
      PAYLOAD="$PAYLOAD, \"body\": \"$BODY\""
    fi
    if [[ -n "$LABELS" ]]; then
      PAYLOAD="$PAYLOAD, \"labels\": $LABELS"
    fi
    PAYLOAD="$PAYLOAD}"
    
    api POST "/repos/$REPO/issues" -d "$PAYLOAD"
    ;;
    
  whoami)
    api GET "/user" | jq -r '{login: .login, html_url: .html_url}'
    ;;
    
  *)
    echo '{"error": "Unknown command. Available: list_repos, clone, commit, create_pr, create_issue, whoami"}' >&2
    exit 1
    ;;
esac
