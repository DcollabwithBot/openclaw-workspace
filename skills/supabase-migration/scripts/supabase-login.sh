#!/bin/bash
# supabase-login.sh - Login to Supabase
# Usage: supabase-login.sh <access-token>

ACCESS_TOKEN="${1:-}"

if [[ -z "$ACCESS_TOKEN" ]]; then
  echo '{"error": "Access token required"}'
  exit 1
fi

# Check if supabase CLI is installed
if ! command -v supabase &> /dev/null; then
  echo "Installing supabase CLI..."
  npm install -g supabase
fi

# Login
echo "$ACCESS_TOKEN" | supabase login 2>&1
echo "{\"status\": \"logged_in\"}"