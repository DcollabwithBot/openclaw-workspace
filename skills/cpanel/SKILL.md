---
name: cpanel
description: Manage cPanel hosting accounts via UAPI. Use when user asks to "check disk usage", "list email accounts", "manage domains", "check Python version", "deploy to cPanel", or any cPanel-related task.
---

# cPanel Management Skill

Interact with cPanel hosting accounts using UAPI (Universal API).

## When to Use

Trigger this skill when the user mentions:
- cPanel operations (disk usage, email accounts, domains)
- Hosting environment info (PHP/Python versions, installed software)
- File management via cPanel
- Database operations in cPanel
- SSL certificate management
- Any task mentioning "cPanel" explicitly

## Prerequisites

1. **API Token** - stored in `~/.openclaw/credentials/cpanel-token`
2. **Server Details** - hostname and username
3. **Network Access** - server must be reachable on port 2083 (HTTPS)

## Quick Start

### Setup

```bash
# Store API token
echo "USERNAME:APITOKEN" > ~/.openclaw/credentials/cpanel-token
chmod 600 ~/.openclaw/credentials/cpanel-token

# Store server hostname
echo "cp05.nordicway.dk" > ~/.openclaw/credentials/cpanel-host
chmod 600 ~/.openclaw/credentials/cpanel-host
```

**Format:** `username:token` (e.g., `kirsogda:XX4UQI4SAB31QF1D5XYDS4M2ABTU79TM`)

### Basic Usage

```bash
# List email accounts
./scripts/cpanel.sh Email list_pops

# Check disk usage
./scripts/cpanel.sh Quota get_quota_info

# List databases
./scripts/cpanel.sh Mysql list_databases

# Get system info
./scripts/cpanel.sh ServerInformation get_server_information
```

## Common Operations

### 1. System Information

```bash
# Get PHP version and details
cpanel_api ServerInformation get_server_information

# Check Python availability
cpanel_api LangPHP php_get_installed_versions

# Get disk usage
cpanel_api Quota get_quota_info
```

### 2. File Management

```bash
# List files in directory
cpanel_api Fileman list_files dir=/home/username/public_html

# Check file permissions
cpanel_api Fileman get_file_information file=/home/username/public_html/index.html

# Upload file (use SFTP/SCP instead for large files)
```

### 3. Database Management

```bash
# List MySQL databases
cpanel_api Mysql list_databases

# Create database
cpanel_api Mysql create_database name=mydb

# List database users
cpanel_api Mysql list_users
```

### 4. Domain Management

```bash
# List domains
cpanel_api DomainInfo list_domains

# Get main domain
cpanel_api DomainInfo main_domain
```

## Core Workflow

1. **Read credentials** from `~/.openclaw/credentials/cpanel-token` and `cpanel-host`
2. **Build API URL**: `https://{host}:2083/execute/{Module}/{function}`
3. **Add Authorization header**: `cpanel username:token`
4. **Parse JSON response**
5. **Handle errors** (check `result` field)

## API Call Pattern

```bash
curl -s -H "Authorization: cpanel username:TOKEN" \
  "https://hostname:2083/execute/Module/function?param=value"
```

**Response format:**
```json
{
  "result": {
    "data": { ... },
    "metadata": { ... },
    "errors": null,
    "status": 1
  }
}
```

## Error Handling

Common errors:
- **401 Unauthorized** - Invalid token or expired
- **404 Not Found** - Invalid module/function name
- **Network timeout** - Check firewall / server reachability
- **status: 0** - API call failed, check `errors` field

## Security

✅ **Safe:**
- Read-only operations (list, get, check)
- Credential storage in `~/.openclaw/credentials/` (600 perms)

⚠️ **Ask first:**
- Creating/deleting databases
- Modifying file permissions
- Adding/removing email accounts
- SSL certificate changes

❌ **Never:**
- Expose API token in logs
- Run destructive operations without confirmation
- Store token in version-controlled files

## Available Modules

Common UAPI modules (see `references/uapi-modules.md` for full list):

| Module | Purpose | Common Functions |
|--------|---------|------------------|
| Email | Email management | list_pops, add_pop, delete_pop |
| Mysql | Database ops | list_databases, create_database |
| Fileman | File operations | list_files, get_file_information |
| Quota | Disk usage | get_quota_info |
| DomainInfo | Domain data | list_domains, main_domain |
| ServerInformation | System info | get_server_information |
| LangPHP | PHP config | php_get_installed_versions |
| **PassengerApps** | **Node.js/Ruby/Python apps** | **list_applications, register_application, ensure_deps** |

## Real-World Example: Check Python Version

```bash
#!/bin/bash
# Check if Python 3.8+ is available on cPanel server

# Read credentials
CREDS=$(cat ~/.openclaw/credentials/cpanel-token)
USERNAME=$(echo $CREDS | cut -d: -f1)
TOKEN=$(echo $CREDS | cut -d: -f2)
HOST=$(cat ~/.openclaw/credentials/cpanel-host)

# Get server info
RESPONSE=$(curl -s -H "Authorization: cpanel $CREDS" \
  "https://$HOST:2083/execute/ServerInformation/get_server_information")

# Parse response
echo "$RESPONSE" | jq '.result.data'
```

**Expected output:**
```json
{
  "hostname": "cp05.nordicway.dk",
  "os": "CentOS Linux",
  "python_version": "3.6.8",
  "php_version": "8.1.27"
}
```

## Limitations

- **Python 3.6 only** - Many cPanel shared hosts run old Python
- **No root access** - Can't install system packages
- **Rate limits** - API calls may be throttled
- **Module availability** - Some modules require specific cPanel features

## Node.js Application Management (PassengerApps)

cPanel uses **Phusion Passenger** to manage Node.js, Ruby, and Python applications via the `PassengerApps` UAPI module.

### List Applications

```bash
./scripts/cpanel.sh PassengerApps list_applications
```

**Response:**
```json
{
  "app_name": {
    "base_uri": "/",
    "deployment_mode": "production",
    "domain": "api.tjekbolig.ai",
    "enabled": 1,
    "name": "tjekbolig-backend",
    "path": "/home/username/api.tjekbolig.ai"
  }
}
```

### Register New Application

```bash
./scripts/cpanel.sh PassengerApps register_application \
  name='my-node-app' \
  path='/home/username/myapp' \
  domain='api.example.com' \
  deployment_mode=production \
  enabled=1
```

**Parameters:**
- `name` - Application name (1-50 chars)
- `path` - Full path to app directory (relative to home)
- `domain` - Domain/subdomain for the app
- `deployment_mode` - `production` or `development`
- `enabled` - `1` to enable, `0` to disable

### Install Dependencies

```bash
# Install npm packages
./scripts/cpanel.sh PassengerApps ensure_deps \
  type=npm \
  app_path='/home/username/api.tjekbolig.ai/'

# Install Python packages
./scripts/cpanel.sh PassengerApps ensure_deps \
  type=pip \
  app_path='/home/username/myapp/'

# Install Ruby gems
./scripts/cpanel.sh PassengerApps ensure_deps \
  type=gem \
  app_path='/home/username/rubyapp/'
```

### 🔄 Restart Application

**Method 1: Via restart.txt (Recommended)**

cPanel/Passenger checks for `tmp/restart.txt` file. Touch it to trigger restart:

```bash
# SSH to server and touch restart file
ssh -p 33 user@cp05.nordicway.dk "touch ~/api.tjekbolig.ai/tmp/restart.txt"
```

**Requirements:**
- Must have `tmp/` directory in app root
- File can be empty - Passenger only checks timestamp
- Happens automatically on next request

**Method 2: Via script helper**

Add to `scripts/cpanel.sh`:

```bash
# Restart Node.js app via SSH
cpanel_restart_nodejs() {
  local app_path="$1"
  ssh -i "$SSH_KEY" -p "$SSH_PORT" "${SSH_USER}@${SSH_HOST}" \
    "mkdir -p ${app_path}/tmp && touch ${app_path}/tmp/restart.txt" \
    && echo "✅ App restart triggered (will happen on next request)"
}
```

**Usage:**
```bash
# Restart api.tjekbolig.ai app
cpanel_restart_nodejs /home/username/api.tjekbolig.ai
```

### Application Structure Requirements

Node.js apps must have:

```
api.tjekbolig.ai/
├── app.js or server.js     # Entry point (default: app.js)
├── package.json            # Dependencies
├── .env                    # Environment variables
├── tmp/                    # REQUIRED for restart.txt
│   └── restart.txt         # Touch to restart
└── node_modules/           # Symlink to virtualenv (created by cPanel)
```

**Note:** `node_modules` should be a symlink to CloudLinux virtualenv, not a regular folder.

### Complete Node.js Deployment Workflow

```bash
# 1. Upload application files
scp -r -P 33 ./myapp/* user@host:~/api.example.com/

# 2. Create tmp directory for restart
ssh -p 33 user@host "mkdir -p ~/api.example.com/tmp"

# 3. Register app in cPanel (if not already)
./scripts/cpanel.sh PassengerApps register_application \
  name='my-api' \
  path='/home/user/api.example.com' \
  domain='api.example.com'

# 4. Install dependencies via cPanel API
./scripts/cpanel.sh PassengerApps ensure_deps \
  type=npm \
  app_path='/home/user/api.example.com/'

# 5. Restart application
ssh -p 33 user@host "touch ~/api.example.com/tmp/restart.txt"

# 6. Test health endpoint
curl https://api.example.com/health
```

## Deployment Considerations

If Python version is too old (like 3.6):
1. **Static frontend only** - Deploy HTML/JS to `public_html/`
2. **External backend** - Host Python/FastAPI elsewhere (Heroku, Railway, Fly.io)
3. **PHP alternative** - Rewrite backend in PHP (widely supported)
4. **Contact host** - Ask if they offer newer Python via CloudLinux Python Selector
5. **Use Node.js instead** - cPanel supports modern Node.js versions (16, 18, 20, 22) via Passenger

## Troubleshooting

**"Authorization failed"**
- Check token format: `username:TOKEN` (no spaces)
- Verify token hasn't expired
- Regenerate token in cPanel interface

**"Module not found"**
- Check module name spelling (case-sensitive)
- Some modules require specific cPanel features
- Contact hosting provider if module should exist

**"Connection timeout"**
- Verify port 2083 is open
- Check server firewall rules
- Try from different network

## Next Steps

1. **Test connection**: `./scripts/cpanel.sh ServerInformation get_server_information`
2. **Check Python**: Look for `python_version` in server info
3. **Deploy frontend**: Copy static files to `public_html/`
4. **Backend strategy**: Based on Python version, choose deployment approach

## References

- `references/uapi-modules.md` - Full UAPI module list
- `references/cpanel-api-examples.md` - More curl examples
- `references/passengerapps.md` - Node.js/Ruby/Python app management
- `scripts/cpanel.sh` - Main script for API calls

## External Links

- [cPanel UAPI Documentation](https://api.docs.cpanel.net/cpanel/introduction)
- [How to Use API Tokens](https://docs.cpanel.net/knowledge-base/security/how-to-use-cpanel-api-tokens/)
- [Quickstart Development Guide](https://api.docs.cpanel.net/guides/quickstart-development-guide)
