# Research Skill - Web Research Workflow

**Purpose:** Replace Mette (researcher agent) with documented workflow.

**Philosophy:** Research doesn't need a dedicated agent - it needs good tool usage.

---

## When to Use

- Find best solution for a problem
- Compare options/products
- Verify facts/claims
- Market research
- Tech stack evaluation

---

## Workflow (For Any Agent)

### 1. Define Query
```
What specific question needs answering?
Narrow scope for better results.
```

### 2. Web Search
```javascript
// Use web_search tool
web_search("query here", {maxResults: 5})
```

### 3. Deep Dive
```javascript
// For promising results, fetch full content
web_fetch("https://url-from-search")
```

### 4. Synthesize
```
Extract key points
Compare options
Note sources
Identify gaps
```

### 5. Report
```markdown
## Research: [Topic]
**Sources:** 5 URLs checked
**Finding:** [Summary]
**Recommendation:** [Action]
**Confidence:** High/Medium/Low
```

---

## Best Practices

**DO:**
- Verify claims across multiple sources
- Note publication dates (recent > old)
- Cite URLs
- Compare pros/cons
- Flag unknowns

**DON'T:**
- Trust single source
- Ignore context
- Copy-paste without understanding
- Assume correlation = causation

---

## Example Usage

### By Anders (Analyst):
```
Task: "Find best VPS hosting under $20/month"

1. web_search("VPS hosting under $20 comparison 2026")
2. web_fetch top 3 results
3. Compare: Hetzner, DigitalOcean, Linode
4. Report findings with pricing table
```

### By Rene (Builder):
```
Task: "Research Next.js 15 breaking changes"

1. web_search("Next.js 15 migration guide breaking changes")
2. web_fetch official migration guide
3. List breaking changes
4. Note impact on our projects
```

---

## Cost

**~$0.01 per query** (web_search + minimal synthesis with Kimi)

Much cheaper than spawning full researcher agent ($0.10-0.50)

---

## Owner

Any agent can use this - primarily Anders (analyst)

**Replaced:** Mette (researcher agent) → workflow documentation
