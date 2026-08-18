#!/usr/bin/env bash
# =============================================================================
# init-networks.sh — Create Docker networks required by this stack (idempotent)
# Safe to run multiple times. Does not modify existing networks.
# =============================================================================
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

create_network() {
  local name=$1
  if docker network inspect "$name" &>/dev/null; then
    echo -e "  ${YELLOW}[exists]${NC}  $name"
  else
    docker network create "$name"
    echo -e "  ${GREEN}[created]${NC} $name"
  fi
}

echo "Initializing Docker networks..."
echo ""

# Shared with the reverse-proxy stack (nginx <-> Grafana)
create_network "proxy-network"

# Shared backend network for the chatbot app being scraped by Prometheus
create_network "backend-chatbot-network"

echo ""
echo -e "${GREEN}Done.${NC}"
