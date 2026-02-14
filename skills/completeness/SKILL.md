# Completeness Skill - "Last 10%" Guardian

**Purpose:** Ensure tasks are actually complete - Danny's ADHD-specific need.

**Why:** Danny (ADHD) executes well but often misses the final 10% polish. This skill catches that.

---

## What It Checks

### Implementation Completeness:
- All referenced files exist
- All TODOs resolved or ticketed in Todoist
- Tests written and passing
- Documentation updated
- Error handling in place
- Logging configured
- Deployment instructions included

### Code Quality:
- Vibe-check score >= 7.0
- Security-scan passes
- No hardcoded credentials

### Deployment Readiness:
- Environment variables documented
- Dependencies listed
- Build succeeds
- No broken imports/references

---

## Usage

```bash
# Check project completeness
./check.sh [project-path]

# With specific checks
./check.sh [project-path] --tests --docs --deploy

# Pre-commit check
./check.sh [project-path] --strict
```

---

## Output Format

```json
{
  "complete": false,
  "score": 85,
  "path": "/path/to/project",
  "missing": [
    "Tests not found",
    "3 TODOs unresolved",
    "README.md missing deployment section"
  ],
  "recommendations": [
    "Add tests for main.js",
    "Resolve TODO on line 42 or create Todoist task",
    "Document deployment steps in README"
  ]
}
```

---

## Integration

### Called by Anders (analyst) before marking task "done":
```bash
# Before reporting task complete
if ! ./completeness/check.sh workspace/projects/tjekbolig-ai; then
  echo "Task not complete - fixing last 10%..."
  # Fix issues, then check again
fi
```

### Part of deployment checklist:
```bash
# Pre-deploy validation
./completeness/check.sh . --strict
```

---

## Scoring

- **100%** - Fully complete
- **90-99%** - Minor issues
- **80-89%** - Some items missing
- **< 80%** - Not ready

**Default threshold:** 90% (acceptable for completion)

---

## Cost

**$0** - No LLM usage, pure file/pattern checks

---

## Owner

Anders (analyst) - runs this before reporting "task complete"
