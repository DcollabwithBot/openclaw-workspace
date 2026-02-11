#!/bin/bash
# supabase-migrate.sh - Run Supabase migrations via CLI
# Usage: supabase-migrate.sh <project-ref> <migration-file>

PROJECT_REF="${1:-}"
MIGRATION_FILE="${2:-}"

if [[ -z "$PROJECT_REF" || -z "$MIGRATION_FILE" ]]; then
  echo '{"error": "Usage: supabase-migrate.sh <project-ref> <migration-file>"}'
  exit 1
fi

if [[ ! -f "$MIGRATION_FILE" ]]; then
  echo "{\"error\": \"Migration file not found: $MIGRATION_FILE\"}"
  exit 1
fi

# Check if supabase CLI is installed
if ! command -v supabase &> /dev/null; then
  echo "{\"error\": \"supabase CLI not installed. Run: npm install -g supabase\"}"
  exit 1
fi

# Run migration
echo "Running migration: $MIGRATION_FILE on project: $PROJECT_REF"
supabase db execute --project-ref "$PROJECT_REF" --file "$MIGRATION_FILE" 2>&1