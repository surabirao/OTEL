#!/usr/bin/env bash
# Create a Grafana API key using the HTTP API.
# Usage: ./create_grafana_token.sh [name] [role] [user] [pass]
# Defaults: name="otel-token", role=Admin, user=admin, pass=admin

set -euo pipefail

NAME=${1:-otel-token}
ROLE=${2:-Admin}
USER=${3:-admin}
PASS=${4:-admin}
GRAFANA_URL=${GRAFANA_URL:-http://localhost:3000}

PAYLOAD=$(cat <<EOF
{ "name": "$NAME", "role": "$ROLE", "secondsToLive": 0 }
EOF
)

echo "Creating Grafana API key '$NAME' with role '$ROLE' against $GRAFANA_URL"

resp=$(curl -s -w "\n%{http_code}" -u "$USER:$PASS" -H "Content-Type: application/json" -d "$PAYLOAD" "$GRAFANA_URL/api/auth/keys")
body=$(echo "$resp" | sed '$d')
code=$(echo "$resp" | tail -n1)

if [ "$code" != "200" ] && [ "$code" != "201" ]; then
  echo "Failed (HTTP $code):"
  echo "$body"
  exit 1
fi

token=$(echo "$body" | /bin/grep -oP '"key"\s*:\s*"\K[^"]+')
if [ -z "$token" ]; then
  echo "Failed to parse token from response:" >&2
  echo "$body"
  exit 1
fi

mkdir -p "$(dirname "./grafana/grafana_api_key.txt")"
echo "$token" > ./grafana/grafana_api_key.txt
echo "Grafana API key saved to ./grafana/grafana_api_key.txt"
echo "$token"
