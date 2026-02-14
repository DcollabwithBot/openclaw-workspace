# Vibe-Check Skill - Code Quality Detector

**Purpose:** Detect "vibe coding" - sloppy, untested, or incomplete code.

**Philosophy:** Quick automated check for common code smells and quality issues.

---

## What It Checks

### Anti-patterns:
- Missing error handling (no try/catch)
- Hardcoded values (should be config/env)
- No input validation
- Missing comments/docstrings
- TODO/FIXME markers left in code
- No tests
- Security anti-patterns (eval, exec with user input)
- Unhandled promises
- Console.log left in production code
- Magic numbers

---

## Usage

```bash
# Check a file
./vibe-check.sh [file-path]

# Check directory
./vibe-check.sh [directory-path]

# With threshold
./vibe-check.sh [path] --threshold 7.0
```

---

## Output Format

```json
{
  "score": 7.5,
  "path": "/path/to/file.js",
  "issues": [
    {
      "severity": "high",
      "line": 42,
      "issue": "Hardcoded API key",
      "suggestion": "Move to environment variables"
    },
    {
      "severity": "medium", 
      "line": 67,
      "issue": "No input validation",
      "suggestion": "Add validation before processing"
    }
  ],
  "recommendations": [
    "Add try/catch blocks",
    "Move config to .env",
    "Add input validation"
  ]
}
```

---

## Integration

### Pre-commit Hook:
```bash
# .git/hooks/pre-commit
#!/bin/bash
if ! /root/.openclaw/workspace/skills/vibe-check/vibe-check.sh . --threshold 7.0; then
  echo "Vibe check failed. Fix issues before committing."
  exit 1
fi
```

### Called by Rene (builder):
After implementing changes, run vibe-check before marking complete.

### Part of "Last 10%" Completeness Check:
Ensures code quality before delivery.

---

## Scoring

- **10.0** - Perfect (no issues)
- **8.0-9.9** - Good (minor issues)
- **6.0-7.9** - Acceptable (some issues)
- **4.0-5.9** - Poor (many issues)
- **< 4.0** - Fail (critical issues)

**Default threshold:** 7.0 (acceptable quality)

---

## Cost

**$0** - No LLM usage, pure static analysis

---

## Owner

Rene (builder) - runs this automatically before completing tasks
