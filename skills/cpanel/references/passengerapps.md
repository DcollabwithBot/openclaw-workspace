# PassengerApps UAPI Module Reference

## Overview

The `PassengerApps` module in cPanel UAPI manages Node.js, Ruby, and Python applications via Phusion Passenger.

**Base URL:** `https://hostname:2083/execute/PassengerApps/`

## Available Functions

### 1. list_applications

Lists all Passenger applications for the account.

**Request:**
```bash
curl -H "Authorization: cpanel username:TOKEN" \
  "https://hostname:2083/execute/PassengerApps/list_applications"
```

**Response:**
```json
{
  "apiversion": 3,
  "func": "list_applications",
  "module": "PassengerApps",
  "result": {
    "data": {
      "app_name1": {
        "base_uri": "/",
        "deployment_mode": "production",
        "deps": {
          "gem": 0,
          "npm": 0,
          "pip": 0
        },
        "domain": "api.example.com",
        "enabled": 1,
        "envvars": {},
        "name": "my-node-app",
        "path": "/home/username/api.example.com"
      }
    },
    "errors": null,
    "messages": null,
    "metadata": {},
    "status": 1,
    "warnings": null
  }
}
```

### 2. register_application

Registers a new Passenger application.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| name | string | Yes | Application name (1-50 chars) |
| path | string | Yes | Full path to app directory |
| domain | string | Yes | Domain/subdomain for the app |
| base_uri | string | No | Base URI path (default: "/") |
| deployment_mode | string | No | "production" or "development" (default: "production") |
| enabled | integer | No | 1=enabled, 0=disabled (default: 1) |
| envvar_name | array | No | Environment variable names |
| envvar_value | array | No | Environment variable values |

**Request:**
```bash
curl -H "Authorization: cpanel username:TOKEN" \
  "https://hostname:2083/execute/PassengerApps/register_application?name=myapp&path=/home/user/myapp&domain=api.example.com"
```

**Response:**
```json
{
  "apiversion": 3,
  "func": "register_application",
  "module": "PassengerApps",
  "result": {
    "data": { ... },
    "status": 1
  }
}
```

### 3. ensure_deps

Installs dependencies for an application (npm, gem, or pip).

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| type | string | Yes | "npm", "gem", or "pip" |
| app_path | string | Yes | Full path to application directory |

**Request:**
```bash
# Install npm packages
curl -H "Authorization: cpanel username:TOKEN" \
  "https://hostname:2083/execute/PassengerApps/ensure_deps?type=npm&app_path=/home/user/myapp/"

# Install Python packages
curl -H "Authorization: cpanel username:TOKEN" \
  "https://hostname:2083/execute/PassengerApps/ensure_deps?type=pip&app_path=/home/user/pyapp/"

# Install Ruby gems
curl -H "Authorization: cpanel username:TOKEN" \
  "https://hostname:2083/execute/PassengerApps/ensure_deps?type=gem&app_path=/home/user/rubyapp/"
```

**Note:** This function starts an async installation process. It may take time to complete.

## Restarting Applications

### Method 1: Touch restart.txt (Recommended)

Passenger monitors `tmp/restart.txt` file. Touch it to trigger restart:

```bash
# Via SSH
ssh user@host "touch /home/user/myapp/tmp/restart.txt"

# Via script
./cpanel.sh PassengerApps list_applications  # Get app path first
ssh -p 33 -i ~/.ssh/key user@cp05.nordicway.dk \
  "touch ~/api.tjekbolig.ai/tmp/restart.txt"
```

**How it works:**
1. Create `tmp/` directory in app root if not exists
2. Touch (create or update timestamp) `restart.txt`
3. Passenger checks this file on next request
4. If timestamp changed, Passenger restarts the app

### Method 2: Restart via cPanel Interface

1. Log in to cPanel
2. Go to **Software → Application Manager**
3. Find your application
4. Click **Restart**

## Application Directory Structure

Required structure for Node.js apps:

```
~/api.example.com/           # Application root (must match registered path)
├── app.js or server.js      # Entry point (default: app.js)
├── package.json             # NPM dependencies
├── .env                     # Environment variables (optional)
├── tmp/                     # REQUIRED for restart.txt
│   └── restart.txt          # Touch to restart
└── node_modules/            # Symlink to CloudLinux virtualenv (auto-created)
```

**Important Notes:**

1. **Entry Point:** Default is `app.js`. If using different name (e.g., `server.js`), you must configure it via Apache config or use symlink.

2. **node_modules:** Must be a symlink to CloudLinux's virtualenv, not a regular directory. Created automatically when using `ensure_deps`.

3. **tmp directory:** Must be manually created for restart.txt to work.

## Environment Variables

To set environment variables during registration:

```bash
curl -H "Authorization: cpanel username:TOKEN" \
  "https://hostname:2083/execute/PassengerApps/register_application?name=myapp&path=/home/user/myapp&domain=api.example.com&envvar_name=NODE_ENV&envvar_value=production&envvar_name=PORT&envvar_value=3000"
```

Or set them in your application code via `.env` file (requires dotenv package).

## Troubleshooting

### App won't restart
- Check `tmp/` directory exists
- Verify `restart.txt` file is being touched (check timestamp: `ls -la tmp/`)
- Check Passenger logs in `/home/user/myapp/logs/`

### 503 Service Unavailable
- Application crashed or failed to start
- Check logs for errors
- Verify entry point file exists (app.js or server.js)
- Ensure `package.json` has valid `start` script

### Dependencies not installing
- Use `ensure_deps` with correct type (npm/gem/pip)
- Check app_path ends with `/`
- Wait a few minutes - installation is async
- Check logs for errors

### Permission denied
- Ensure files are owned by cPanel user (not root)
- Check file permissions: `chmod 755` for directories, `644` for files

## CloudLinux Specifics

On CloudLinux servers:

1. **Virtual Environments:** Each app gets isolated virtualenv
2. **Node.js Versions:** Multiple versions available (16, 18, 20, 22)
3. **Selector:** Use CloudLinux Node.js Selector in cPanel to choose version
4. **Symlinks:** `node_modules` is automatically symlinked to virtualenv

## External References

- [cPanel Application Manager Docs](https://docs.cpanel.net/cpanel/software/application-manager)
- [How to Install Node.js Application](https://docs.cpanel.net/knowledge-base/web-services/how-to-install-a-node.js-application/)
- [Passenger Restarting Applications](https://www.phusionpassenger.com/library/admin/apache/restart_app.html)
- [cPanel UAPI PassengerApps](https://api.docs.cpanel.net/openapi/cpanel/operation/list_applications/)
