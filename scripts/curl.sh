#! /usr/bin/env bash

# CURL SCRIPT TO HIT LOCAL HEALTH AND PROM-CLIENT METRICS ENDPOINTS
# Chatbot API must be running locally on the specified port 
# for this script to work correctly

set -euo pipefail

CHATBOT_API_PORT=8181

TARGET_URL="http://localhost:${CHATBOT_API_PORT}/health"
METRICS_URL="http://localhost:${CHATBOT_API_PORT}/api/v1/test/metrics"

echo "===== CURL.SH ====="
echo ""
echo "===== chatbot-dev ===="
echo ""
echo "===== Requesting: ${TARGET_URL} ====="
echo ""

# fetch format and capture exit status safely
health_json=$(curl -sS "$TARGET_URL")
working_metrics=$(curl -sS "$METRICS_URL")
echo "==== local HEALTH CHECK ===="
echo "$health_json" | jq .
echo ""
echo "==== WORKING METRICS - JSON (prom-client: chatbot-dev) ===="
echo "$working_metrics" | jq .
