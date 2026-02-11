#!/bin/bash
# frontend-test.sh - Frontend testing wrapper
# Usage: ./frontend-test.sh <url> [options]

set -euo pipefail

URL="${1:-}"
MODE="${2:-auto}"  # auto, api, manual

if [[ -z "$URL" ]]; then
    echo "Usage: $0 <url> [--mode=api|manual]"
    echo ""
    echo "Examples:"
    echo "  $0 https://tjekbolig.ai"
    echo "  $0 https://tjekbolig.ai --mode=api"
    exit 1
fi

echo "🧪 Frontend Test: $URL"
echo "======================"
echo ""

# API Health Check (always works)
echo "📡 API Health Check..."
API_URL=$(echo "$URL" | sed 's|tjekbolig.ai|api.tjekbolig.ai|')
HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/health" 2>/dev/null || echo "000")

if [[ "$HEALTH_STATUS" == "200" ]]; then
    echo "  ✅ Backend: $API_URL/health (200 OK)"
    curl -s "$API_URL/health" | jq -r ' "     Timestamp: \(.timestamp)" ' 2>/dev/null || true
else
    echo "  ⚠️  Backend: $API_URL/health (HTTP $HEALTH_STATUS)"
fi
echo ""

# Frontend Load Test
echo "🌐 Frontend Load Test..."
FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL" 2>/dev/null || echo "000")
FRONTEND_SIZE=$(curl -s "$URL" 2>/dev/null | wc -c)

if [[ "$FRONTEND_STATUS" == "200" ]]; then
    echo "  ✅ Frontend: $URL (200 OK, ${FRONTEND_SIZE} bytes)"
else
    echo "  ❌ Frontend: $URL (HTTP $FRONTEND_STATUS)"
fi
echo ""

# API Endpoints Test
echo "🔌 API Endpoints..."

# Test upload endpoint
UPLOAD_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API_URL/upload" 2>/dev/null || echo "000")
if [[ "$UPLOAD_STATUS" == "200" ]]; then
    echo "  ✅ POST /upload (200 OK)"
else
    echo "  ⚠️  POST /upload (HTTP $UPLOAD_STATUS)"
fi

# Test cases endpoint
CASES_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/cases" 2>/dev/null || echo "000")
if [[ "$CASES_STATUS" == "200" ]]; then
    echo "  ✅ GET /cases (200 OK)"
else
    echo "  ⚠️  GET /cases (HTTP $CASES_STATUS)"
fi
echo ""

# CORS Check
echo "🌐 CORS Headers Check..."
CORS_HEADERS=$(curl -s -I -X OPTIONS "$API_URL/upload" 2>/dev/null | grep -i "access-control" || echo "None")
if [[ "$CORS_HEADERS" != "None" ]]; then
    echo "  ✅ CORS headers present"
    echo "$CORS_HEADERS" | head -3 | sed 's/^/     /'
else
    echo "  ⚠️  No CORS headers detected"
fi
echo ""

# Manual Testing Checklist
echo "📝 Manual Testing Checklist:"
echo "  [ ] Open $URL in browser"
echo "  [ ] Open DevTools (F12), check Console for errors"
echo "  [ ] Drag a PDF file to upload area"
echo "  [ ] Click 'Upload og analyser' button"
echo "  [ ] Verify success/feedback message appears"
echo "  [ ] Test on mobile (responsive)"
echo ""

echo "📊 Summary"
echo "=========="
echo "API Health: $([[ "$HEALTH_STATUS" == "200" ]] && echo "✅" || echo "❌")"
echo "Frontend:   $([[ "$FRONTEND_STATUS" == "200" ]] && echo "✅" || echo "❌")"
echo "Upload:     $([[ "$UPLOAD_STATUS" == "200" ]] && echo "✅" || echo "⚠️")"
echo "Cases:      $([[ "$CASES_STATUS" == "200" ]] && echo "✅" || echo "⚠️")"
echo ""
echo "🚀 For browser automation testing:"
echo "   1. Install: https://chromewebstore.google.com/detail/openclaw-browser-relay/ahjdmconkfkbbmlaoakkpclmgdmemmah"
echo "   2. Open $URL in Chrome"
echo "   3. Click extension icon"
echo "   4. Ask me to 'test the frontend'"
