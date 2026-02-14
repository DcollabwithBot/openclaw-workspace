# Security Skill - Bent's Expertise as Scripts

**Purpose:** Replace Bent (security agent) with deterministic security checking tools.

**Philosophy:** Security checks should be fast, deterministic, and not burn LLM tokens.

---

## Available Tools

### 1. Security Scan
```bash
./security-scan.sh --target [path] --level [basic|deep]
```

Scans code/config for common security issues:
- Hardcoded secrets (API keys, passwords)
- Insecure file permissions
- Known vulnerability patterns
- Security anti-patterns (eval, exec of user input)

**Output:** JSON report with severity levels

---

### 2. Credential Check
```bash
./check-credentials.sh
```

Checks all credentials in PROJECT.md files:
- Rotation dates
- Alerts for credentials expiring in <14 days
- Verifies credential prefixes match expected format

**Output:** List of credentials needing rotation

---

### 3. File Permission Audit
```bash
./audit-permissions.sh [path]
```

Audits file permissions for security issues:
- World-writable files
- Executable configs
- Secrets with wrong permissions (should be 600)

**Output:** List of permission issues

---

### 4. Dependency Vulnerability Check
```bash
./check-vulns.sh [package.json|requirements.txt|go.mod]
```

Checks dependencies for known vulnerabilities:
- Uses `npm audit`, `pip-audit`, or `govulncheck`
- Reports HIGH/CRITICAL issues only

**Output:** Vulnerability report

---

## Integration

### Called by Rene (builder) after implementation:
```bash
# Before marking task complete
./security-scan.sh --target workspace/projects/tjekbolig-ai --level basic

# If issues found
# → Rene fixes them before continuing
```

### Called by Heartbeat monthly:
```bash
# Check credential rotation
./check-credentials.sh

# If expiring soon
# → Alert Danny
```

---

## Cost

**$0** - No LLM calls, pure bash + standard tools

---

## Maintenance

**Owner:** Rene (inherited from Bent)  
**Update frequency:** As new security patterns emerge  
**Location:** `/root/.openclaw/workspace/skills/security/`
