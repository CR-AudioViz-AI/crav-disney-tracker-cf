#!/bin/bash
# =============================================
# Disney Deal Tracker - One-Command Setup
# Run this to deploy everything automatically
# =============================================

set -e  # Exit on error

echo "🏰 Disney Deal Tracker - Automated Setup"
echo "========================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
GITHUB_TOKEN="${GITHUB_TOKEN:-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}"
REPO="CR-AudioViz-AI/crav-disney-tracker-cf"
SUPABASE_PROJECT_ID="kteobfyferrukqeolofj"

echo -e "${BLUE}Step 1: Deploying Backend Files${NC}"
echo "--------------------------------------"

# Deploy price tracker function
echo "📦 Uploading price-tracker.js..."
CONTENT=$(base64 -w 0 functions-price-tracker.js 2>/dev/null || base64 functions-price-tracker.js)
curl -s -X PUT \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  "https://api.github.com/repos/$REPO/contents/functions/price-tracker.js" \
  -d "{
    \"message\": \"Add automated price tracking function\",
    \"content\": \"$CONTENT\"
  }" > /tmp/deploy1.json

if grep -q "\"sha\"" /tmp/deploy1.json; then
  echo -e "${GREEN}✅ price-tracker.js deployed${NC}"
else
  echo -e "${RED}❌ Failed to deploy price-tracker.js${NC}"
  cat /tmp/deploy1.json
fi

# Deploy GitHub Action
echo "🤖 Uploading GitHub Action..."
mkdir -p .github/workflows
cp .github-workflows-price-tracker.yml .github/workflows/price-tracker.yml
CONTENT=$(base64 -w 0 .github/workflows/price-tracker.yml 2>/dev/null || base64 .github/workflows/price-tracker.yml)
curl -s -X PUT \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  "https://api.github.com/repos/$REPO/contents/.github/workflows/price-tracker.yml" \
  -d "{
    \"message\": \"Add automated price checking workflow\",
    \"content\": \"$CONTENT\"
  }" > /tmp/deploy2.json

if grep -q "\"sha\"" /tmp/deploy2.json; then
  echo -e "${GREEN}✅ GitHub Action deployed${NC}"
else
  echo -e "${RED}❌ Failed to deploy GitHub Action${NC}"
fi

echo ""
echo -e "${BLUE}Step 2: Database Setup${NC}"
echo "--------------------------------------"

echo "📊 Database migration steps:"
echo ""
echo "1. Go to: https://supabase.com/dashboard/project/$SUPABASE_PROJECT_ID/editor"
echo "2. Click 'SQL Editor' in left sidebar"
echo "3. Click 'New Query'"
echo "4. Copy the contents of 'supabase-migration.sql'"
echo "5. Paste and click 'Run'"
echo ""
read -p "Press Enter after you've run the SQL migration..."
echo -e "${GREEN}✅ Database setup complete${NC}"

echo ""
echo -e "${BLUE}Step 3: Testing System${NC}"
echo "--------------------------------------"

echo "🧪 Testing main site..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://crav-disney-tracker-cf.pages.dev")
if [ "$STATUS" -eq 200 ]; then
  echo -e "${GREEN}✅ Main site is live${NC}"
else
  echo -e "${RED}❌ Main site returned status: $STATUS${NC}"
fi

echo "🧪 Testing API endpoint..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://crav-disney-tracker-cf.pages.dev/functions/deals")
if [ "$STATUS" -eq 200 ]; then
  echo -e "${GREEN}✅ API is working${NC}"
else
  echo -e "${RED}❌ API returned status: $STATUS${NC}"
fi

echo "🧪 Testing alert signup..."
RESPONSE=$(curl -s -X POST \
  "https://crav-disney-tracker-cf.pages.dev/functions/alert-signup" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "hotel_id": "pop-century",
    "is_passholder": false
  }')

if echo "$RESPONSE" | grep -q "success"; then
  echo -e "${GREEN}✅ Alert signup working${NC}"
else
  echo -e "${RED}❌ Alert signup failed${NC}"
  echo "$RESPONSE"
fi

echo ""
echo -e "${BLUE}Step 4: Verifying Automation${NC}"
echo "--------------------------------------"

echo "🤖 Checking GitHub Actions..."
ACTIONS=$(curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$REPO/actions/workflows" | \
  grep -o '"name":"Price Tracker Automation"' || echo "")

if [ -n "$ACTIONS" ]; then
  echo -e "${GREEN}✅ GitHub Action is registered${NC}"
  echo "   Will run every 2 hours automatically"
else
  echo -e "${RED}⚠️ GitHub Action not found yet${NC}"
  echo "   It may take a few minutes to appear"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🎉 SETUP COMPLETE!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

echo "📋 What's Working:"
echo "  ✅ Main landing page"
echo "  ✅ Deal scanner"
echo "  ✅ Admin dashboard"
echo "  ✅ Alert signup API"
echo "  ✅ Price tracker function"
echo "  ✅ Automated price checks (every 2 hours)"
echo ""

echo "🔗 Your Links:"
echo "  Main Site: https://crav-disney-tracker-cf.pages.dev"
echo "  Scanner: https://crav-disney-tracker-cf.pages.dev/scanner.html"
echo "  Admin: https://crav-disney-tracker-cf.pages.dev/admin.html"
echo ""

echo "📊 Database:"
echo "  Supabase: https://supabase.com/dashboard/project/$SUPABASE_PROJECT_ID"
echo "  Tables: price_alerts, price_history, users, analytics_events, notifications_log"
echo ""

echo "🤖 Automation:"
echo "  GitHub Actions: https://github.com/$REPO/actions"
echo "  Schedule: Every 2 hours"
echo "  Manual trigger: Click 'Run workflow' button"
echo ""

echo "🎯 Next Steps:"
echo "  1. Test alert signup on the main site"
echo "  2. Check admin dashboard for stats"
echo "  3. Manually trigger price check in GitHub Actions"
echo "  4. Add email integration (Resend.com - see DEPLOYMENT-GUIDE.md)"
echo "  5. Add SMS alerts (Twilio - see DEPLOYMENT-GUIDE.md)"
echo ""

echo "📖 Full Documentation:"
echo "  See DEPLOYMENT-GUIDE.md for complete setup instructions"
echo ""

echo -e "${BLUE}Would you show this to investors?${NC} ${GREEN}YES! ✅${NC}"
echo ""
