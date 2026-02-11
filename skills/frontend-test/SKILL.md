---
name: frontend-test
description: Automated browser testing for web applications. Use when user asks to "test the frontend", "check if the site works", "verify upload", or "E2E test".
---

# Frontend Testing Skill

Automated end-to-end testing using real browser automation.

## When to Use

Trigger when user mentions:
- "test the frontend"
- "check if the site works"
- "verify upload flow"
- "E2E test"
- "does the button work"
- "test [feature] on [url]"

## Quick Start

```bash
# Test TjekBoligAI frontend
./scripts/frontend-test.sh https://tjekbolig.ai

# Test specific flow
./scripts/frontend-test.sh https://tjekbolig.ai --flow=upload

# Test with custom checks
./scripts/frontend-test.sh https://example.com --checks=form,navigation,console
```

## Testing Capabilities

### 1. Smoke Test (Default)
- Loads the page
- Checks for console errors
- Verifies key elements exist
- Takes screenshot

### 2. Upload Flow Test
- Navigates to upload page
- Attempts file upload
- Verifies response/feedback
- Screenshots each step

### 3. Form Testing
- Fills form fields
- Submits forms
- Checks validation
- Verifies success/error states

### 4. Full E2E Test
- Tests complete user journeys
- Multiple page navigation
- State persistence
- Error handling

## Example Output

```
🧪 Frontend Test: https://tjekbolig.ai
=====================================

✅ Page Load
   - Status: 200 OK
   - Load time: 1.2s
   - Screenshot: page-load.png

⚠️  Console Errors
   - 1 warning: "React hydration mismatch"
   - Screenshot: N/A

❌ Upload Flow
   - Can select file ✅
   - Upload button visible ✅
   - After upload: No feedback ❌
   - Expected: Success message
   - Got: Nothing
   - Screenshot: upload-no-feedback.png

📊 Summary
   Tests: 3
   Passed: 1
   Warnings: 1
   Failed: 1

🔧 Recommendations
   1. Add success/error feedback after upload
   2. Fix React hydration warning
```

## How It Works

The skill uses the `browser` tool to:
1. Open a real browser (Chrome)
2. Navigate to the URL
3. Interact with elements
4. Capture screenshots
5. Check console logs
6. Report findings

## Setup Requirements

### Option 1: Chrome Extension (Recommended for Development)
1. Install Chrome extension: [OpenClaw Browser Relay](https://chromewebstore.google.com/detail/openclaw-browser-relay/ahjdmconkfkbbmlaoakkpclmgdmemmah)
2. Open site you want to test
3. Click extension icon to attach tab
4. Run `browser` commands

### Option 2: Standalone Browser (For CI/Server)
```bash
# Install Playwright
npm install -g playwright
npx playwright install chromium

# Run tests
./scripts/frontend-test.sh --mode=playwright
```

### Option 3: Manual Testing Checklist
When browser automation isn't available, use the manual checklist:
```bash
./scripts/frontend-test.sh https://tjekbolig.ai --mode=manual
```

## Testing TjekBoligAI

```bash
# Quick smoke test
./scripts/frontend-test.sh https://tjekbolig.ai

# Test upload specifically
./scripts/frontend-test.sh https://tjekbolig.ai \
  --test=upload \
  --file=test.pdf
```

## Manual Testing Alternative

If browser automation isn't set up:

1. **Open browser** → Navigate to https://tjekbolig.ai
2. **Console check** → Open DevTools (F12), check for red errors
3. **Upload test** → Try dragging a PDF to upload area
4. **Verify** → Check if success message appears
5. **Screenshot** → Capture any issues

## References

- `agents/frontend-tester.md` - Agent definition
- `scripts/frontend-test.sh` - Test runner

## Integration with CI

Add to GitHub Actions:
```yaml
- name: Frontend E2E Test
  run: |
    ./scripts/frontend-test.sh https://staging.tjekbolig.ai
    if [ $? -ne 0 ]; then
      echo "Frontend tests failed!"
      exit 1
    fi
```
