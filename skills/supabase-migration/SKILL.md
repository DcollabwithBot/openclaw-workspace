---
name: supabase-migration
description: Run SQL migrations on Supabase projects using the Supabase CLI. Use when the user asks to "run migration on Supabase", "create Supabase table", "setup Supabase database", or "execute SQL on Supabase". Handles supabase CLI installation, login, and migration execution.
---

# Supabase Migration

Run SQL migrations on Supabase PostgreSQL databases.

## Prerequisites

1. Supabase project (get project ref from dashboard URL)
2. Supabase access token (from https://supabase.com/dashboard/account/tokens)
3. SQL migration file

## Quick Start

### 1. Login to Supabase
```bash
./skills/supabase-migration/scripts/supabase-login.sh <your-access-token>
```

### 2. Run Migration
```bash
./skills/supabase-migration/scripts/supabase-migrate.sh <project-ref> <migration-file.sql>
```

**Example:**
```bash
./skills/supabase-migration/scripts/supabase-migrate.sh \
  xveokbfxqjujsajqtyda \
  ./supabase/migrations/001_initial.sql
```

## Finding Your Project Ref

From Supabase dashboard URL:
```
https://supabase.com/dashboard/project/xveokbfxqjujsajqtyda
                          └──────────────────────────────┘
                                    project-ref
```

## Creating Access Token

1. Go to https://supabase.com/dashboard/account/tokens
2. Click "Generate New Token"
3. Copy token immediately (shown only once)

## Troubleshooting

**"supabase CLI not installed"**
```bash
npm install -g supabase
```

**"Invalid project ref"**
- Check project ref in dashboard URL
- Ensure you're logged in: `supabase projects list`

**"Permission denied"**
- Regenerate access token
- Ensure token has Database Admin scope