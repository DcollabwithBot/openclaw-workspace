# cPanel Python App Setup Guide

## Overview

cPanel's "Setup Python App" feature allows running Python applications with modern versions (3.8+) even if the system default is older.

## Creating a Python Application

### Via cPanel Interface

1. Navigate to **Software → Setup Python App**
2. Click **Create Application**
3. Configure:
   - **Python version**: 3.8.20 (or newer if available)
   - **Application root**: Physical path (e.g., `/home/username/tjekbolig-backend`)
   - **Application URL**: HTTP path (e.g., `tjekbolig.ai/api` or subdomain)
   - **Application startup file**: Entry point (e.g., `passenger_wsgi.py`)
   - **WSGI callable**: Usually `application` or `app`

### Via UAPI (if available)

Check if Python App module exists:
```bash
cpanel.sh LangPHP php_get_vhost_versions
# or
cpanel.sh Python list_apps  # May not exist in all cPanel versions
```

## Application Structure for cPanel

cPanel uses **Passenger** (Phusion Passenger) to run Python apps. It expects a specific structure:

```
tjekbolig-backend/
├── passenger_wsgi.py     # Entry point (required)
├── app/
│   ├── __init__.py
│   ├── main.py          # Your FastAPI app
│   └── ...
├── requirements.txt
├── .env
└── tmp/                  # Passenger restart trigger
    └── restart.txt
```

## passenger_wsgi.py Template

For **FastAPI** applications:

```python
import sys
import os

# Add application directory to Python path
INTERP = os.path.expanduser("~/virtualenv/tjekbolig-backend/3.8/bin/python3")
if sys.executable != INTERP:
    os.execl(INTERP, INTERP, *sys.argv)

# Set application directory
sys.path.insert(0, os.path.dirname(__file__))

# Import FastAPI app
from app.main import app as application

# Passenger expects 'application' callable
# application = app  # Already named 'application' above
```

For **Flask** applications:

```python
import sys
import os

INTERP = os.path.expanduser("~/virtualenv/tjekbolig-backend/3.8/bin/python3")
if sys.executable != INTERP:
    os.execl(INTERP, INTERP, *sys.argv)

sys.path.insert(0, os.path.dirname(__file__))

from app import app as application
```

## Deployment Workflow

### 1. Upload Application Files

```bash
# Via SCP
scp -r -i ~/.ssh/key -P 33 tjekbolig-backend/ user@host:~/

# Or via SSH and git
ssh -i ~/.ssh/key -P 33 user@host
cd ~
git clone https://github.com/user/repo.git tjekbolig-backend
```

### 2. Create Python App in cPanel

Via cPanel interface:
- **Python version**: 3.8.20
- **Application root**: `/home/username/tjekbolig-backend`
- **Application URL**: Choose domain/subdomain or path
- **Application startup file**: `passenger_wsgi.py`

This will:
- Create virtual environment in `~/virtualenv/tjekbolig-backend/3.8/`
- Set up Passenger configuration
- Create Apache/Nginx rules

### 3. Install Dependencies

After creating the app, cPanel shows a command to enter the virtual environment:

```bash
source ~/virtualenv/tjekbolig-backend/3.8/bin/activate
cd ~/tjekbolig-backend
pip install -r requirements.txt
```

Or via SSH:

```bash
ssh -i ~/.ssh/key -P 33 user@host << 'ENDSSH'
source ~/virtualenv/tjekbolig-backend/3.8/bin/activate
cd ~/tjekbolig-backend
pip install -r requirements.txt
ENDSSH
```

### 4. Configure Environment

```bash
# Create .env file
cat > ~/tjekbolig-backend/.env << 'EOF'
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_KEY=sb_publishable_xxx
SUPABASE_SECRET=sb_secret_xxx
BACKEND_PORT=8000
EOF

chmod 600 ~/tjekbolig-backend/.env
```

### 5. Restart Application

Create or touch the restart file:

```bash
mkdir -p ~/tjekbolig-backend/tmp
touch ~/tjekbolig-backend/tmp/restart.txt
```

Passenger monitors this file and restarts the app when it changes.

## Troubleshooting

### Application won't start

Check Passenger logs:
```bash
tail -f ~/logs/tjekbolig-backend_error_log
```

Common issues:
- Missing `passenger_wsgi.py`
- Wrong virtual environment path in passenger_wsgi.py
- Import errors (missing dependencies)
- Wrong WSGI callable name

### Dependencies won't install

```bash
# Upgrade pip first
source ~/virtualenv/tjekbolig-backend/3.8/bin/activate
pip install --upgrade pip

# Install with verbose output
pip install -r requirements.txt -v
```

### App returns 500 error

Check:
1. Passenger error logs: `~/logs/*_error_log`
2. Application logs (if you have logging configured)
3. File permissions (should be readable by Apache user)

### Need to restart

```bash
touch ~/tjekbolig-backend/tmp/restart.txt
```

Or via cPanel interface: Click "Restart" button on the Python App

## URL Configuration

### Subdomain (recommended)
- Create subdomain: `api.tjekbolig.ai`
- Point to application root
- Access: `https://api.tjekbolig.ai/`

### Path-based
- Application URL: `tjekbolig.ai/api`
- Access: `https://tjekbolig.ai/api/`
- May require `.htaccess` tweaking

### Custom domain
- Point domain DNS to cPanel server
- Create domain in cPanel
- Set as Application URL

## FastAPI Compatibility Notes

FastAPI is ASGI-based, but Passenger is WSGI. Solutions:

1. **Use Uvicorn worker** (if Passenger allows):
   ```python
   # passenger_wsgi.py
   import uvicorn
   from app.main import app
   
   if __name__ == "__main__":
       uvicorn.run(app, host="0.0.0.0", port=8000)
   ```

2. **Use ASGI-to-WSGI adapter**:
   ```python
   # passenger_wsgi.py
   from asgiref.wsgi import WsgiToAsgi
   from app.main import app as fastapi_app
   
   application = WsgiToAsgi(fastapi_app)
   ```
   
   Add to requirements.txt:
   ```
   asgiref>=3.4.0
   ```

3. **Switch to Flask** (if FastAPI doesn't work):
   Flask is WSGI-native and works perfectly with Passenger.

## Performance Considerations

- Passenger spawns processes on-demand
- First request may be slow (process spawn)
- Keep-alive helps maintain processes
- Consider increasing Passenger process pool in cPanel

## Security

- Set `.env` file permissions: `chmod 600 .env`
- Don't commit `.env` to git
- Use cPanel's "Protected Directories" for sensitive paths
- Enable HTTPS (Let's Encrypt available in cPanel)

## References

- [Passenger + Python Guide](https://www.phusionpassenger.com/library/walkthroughs/deploy/python/)
- [cPanel Python App Documentation](https://docs.cpanel.net/cpanel/software/setup-python-app/)
