#!/bin/bash
# Check API quotas for various providers
# Returns JSON with quota status
#
# Usage: ./check-quotas.sh
#
# Configure paths below or set environment variables:
#   OPENCLAW_CREDENTIALS_DIR - Path to your secrets directory

set -euo pipefail

# Configuration
CREDENTIALS_DIR="${OPENCLAW_CREDENTIALS_DIR:-$HOME/.openclaw/credentials}"

# Check OpenRouter quota
check_openrouter() {
    # Try credentials file first, then config
    local api_key=$(cat "$CREDENTIALS_DIR/openrouter" 2>/dev/null || \
                    jq -r '.models.providers.openrouter.apiKey' "$HOME/.openclaw/openclaw.json" 2>/dev/null || echo "")
    
    if [ -z "$api_key" ] || [ "$api_key" = "null" ]; then
        echo "null"
        return
    fi
    
    curl -s https://openrouter.ai/api/v1/auth/key \
        -H "Authorization: Bearer $api_key" 2>/dev/null | jq '{
            usage: .data.usage,
            usage_daily: .data.usage_daily,
            usage_monthly: .data.usage_monthly,
            limit: .data.limit,
            limit_remaining: .data.limit_remaining,
            is_free_tier: .data.is_free_tier,
            note: (if .data.limit == null then "Pay-as-you-go: no fixed limit" else null end)
        }' || echo "null"
}

# Check OpenAI API quota (just verify key works)
check_openai() {
    local api_key=$(cat "$CREDENTIALS_DIR/openai" 2>/dev/null || echo "")
    
    if [ -z "$api_key" ]; then
        echo "null"
        return
    fi
    
    # OpenAI doesn't have a simple quota endpoint, verify key works
    curl -s https://api.openai.com/v1/models \
        -H "Authorization: Bearer $api_key" 2>/dev/null | \
        jq -r 'if .error then "error: \(.error.message)" else "valid" end' || echo "null"
}

# Check Anthropic API (verify key works)
check_anthropic() {
    # Anthropic uses auth profiles, not direct API keys in our setup
    # Check if profile exists in config
    if jq -e '.auth.profiles["anthropic:default"]' "$HOME/.openclaw/openclaw.json" >/dev/null 2>&1; then
        echo '"configured"'
    else
        echo "null"
    fi
}

# Check GitHub API rate limit
check_github() {
    local api_key=$(cat "$CREDENTIALS_DIR/github" 2>/dev/null || echo "")
    
    if [ -z "$api_key" ]; then
        echo "null"
        return
    fi
    
    curl -s https://api.github.com/rate_limit \
        -H "Authorization: Bearer $api_key" 2>/dev/null | jq '{
            core_limit: .resources.core.limit,
            core_remaining: .resources.core.remaining,
            core_reset: .resources.core.reset,
            search_limit: .resources.search.limit,
            search_remaining: .resources.search.remaining
        }' || echo "null"
}

# Check Todoist API (just verify key works)
check_todoist() {
    local api_key=$(cat "$CREDENTIALS_DIR/todoist" 2>/dev/null || echo "")
    
    if [ -z "$api_key" ]; then
        echo "null"
        return
    fi
    
    # Verify key works by getting projects
    curl -s https://api.todoist.com/rest/v2/projects \
        -H "Authorization: Bearer $api_key" 2>/dev/null | \
        jq -r 'if type == "array" then "valid" else "error" end' || echo "null"
}

# Build combined JSON output
openrouter_quota=$(check_openrouter)
openai_status=$(check_openai)
anthropic_status=$(check_anthropic)
github_quota=$(check_github)
todoist_status=$(check_todoist)

jq -n \
    --argjson openrouter "$openrouter_quota" \
    --arg openai "$openai_status" \
    --arg anthropic "$anthropic_status" \
    --argjson github "$github_quota" \
    --arg todoist "$todoist_status" \
    '{
        openrouter: $openrouter,
        openai_api: $openai,
        anthropic_api: $anthropic,
        github: $github,
        todoist: $todoist,
        checked_at: (now | strftime("%Y-%m-%dT%H:%M:%SZ"))
    }'
