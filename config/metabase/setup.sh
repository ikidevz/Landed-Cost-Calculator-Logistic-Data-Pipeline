#!/bin/bash
# Run once after: docker-compose up -d

set -e

METABASE_URL="http://metabase:3000"
MB_USER="admin@landedcost.local"
MB_PASSWORD="landedcost_admin#001"
MB_FIRST="Iki"
MB_LAST="DataEngineer"

echo "Waiting for Metabase to be ready..."
until curl -sf --max-time 30 "$METABASE_URL/api/health" | grep -q '"status":"ok"'; do
  echo "Still waiting..."
  sleep 5
done

echo "Metabase is up. Fetching setup token..."
SETUP_TOKEN=$(curl -sf --max-time 30 "$METABASE_URL/api/session/properties" \
  | grep -o '"setup-token":"[^"]*"' \
  | sed 's/"setup-token":"//;s/"//')

if [ -z "$SETUP_TOKEN" ] || [ "$SETUP_TOKEN" = "null" ]; then
  echo "ERROR: Could not fetch setup token. Metabase may already be set up."
  exit 1
fi

echo "Setup token: $SETUP_TOKEN"

echo "Creating admin user..."
RESPONSE=$(curl -sf --max-time 30 -X POST "$METABASE_URL/api/setup" \
  -H "Content-Type: application/json" \
  -d "{
    \"token\": \"$SETUP_TOKEN\",
    \"user\": {
      \"first_name\": \"$MB_FIRST\",
      \"last_name\": \"$MB_LAST\",
      \"email\": \"$MB_USER\",
      \"password\": \"$MB_PASSWORD\",
      \"site_name\": \"Landed Cost Pipeline\"
    },
    \"prefs\": {
      \"site_name\": \"Landed Cost Pipeline\",
      \"allow_tracking\": false
    }
  }")

SESSION=$(echo "$RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | sed 's/"id":"//;s/"//')

if [ -z "$SESSION" ] || [ "$SESSION" = "null" ]; then
  echo "ERROR: Could not create admin user. Response: $RESPONSE"
  exit 1
fi

echo "Admin user created. Session: $SESSION"

echo "Connecting landed_cost_db database..."
curl -sf --max-time 30 -X POST "$METABASE_URL/api/database" \
  -H "Content-Type: application/json" \
  -H "X-Metabase-Session: $SESSION" \
  -d "{
    \"name\": \"Landed Cost DB\",
    \"engine\": \"postgres\",
    \"details\": {
      \"host\": \"postgres\",
      \"port\": 5432,
      \"dbname\": \"landed_cost_db\",
      \"user\": \"${POSTGRES_USER:-landed_cost_user}\",
      \"password\": \"${POSTGRES_PASSWORD:-landed_cost_password}\",
      \"schema-filters-type\": \"inclusion\",
      \"schema-filters-patterns\": \"marts,staging\"
    }
  }"

echo ""
echo "Done! Login at http://localhost:3000"
echo "  Email:    $MB_USER"
echo "  Password: $MB_PASSWORD"