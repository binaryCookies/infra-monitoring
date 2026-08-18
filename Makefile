# ============================================
# Makefile for Monitoring Stack
# ============================================
# Purpose: Manage the observability stack
#          (Prometheus, Grafana, cAdvisor, node-exporter,
#           Pushgateway, Portainer)
# Usage: make <target>

# ============================================
# PROJECT CONFIGURATION
# ============================================
PROJECT_NAME    := monitoring
COMPOSE_FILE    := docker-compose.yml
ENV_FILE        := .env
COMPOSE         := docker compose -f $(COMPOSE_FILE)

PROM_CONTAINER  := monitoring-prometheus
GRAFANA_CONTAINER := monitoring-grafana

# ============================================
# COLOR OUTPUT
# ============================================
COLOR_RESET  := \033[0m
COLOR_BOLD   := \033[1m
COLOR_GREEN  := \033[32m
COLOR_YELLOW := \033[33m
COLOR_BLUE   := \033[34m
COLOR_CYAN   := \033[36m

# ============================================
# PHONY TARGETS
# ============================================
.PHONY: help up down restart logs ps health \
        shell-prometheus shell-grafana prune init

.DEFAULT_GOAL := help

# ============================================
# HELP
# ============================================
help:
	@echo "$(COLOR_BOLD)╔════════════════════════════════════════════════════╗$(COLOR_RESET)"
	@echo "$(COLOR_BOLD)║   $(PROJECT_NAME) - Observability Stack            ║$(COLOR_RESET)"
	@echo "$(COLOR_BOLD)╚════════════════════════════════════════════════════╝$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_GREEN)🚀 Stack Control:$(COLOR_RESET)"
	@echo "  make init           - Create required Docker networks (idempotent)"
	@echo "  make up             - Start all monitoring services (detached)"
	@echo "  make down           - Stop and remove containers"
	@echo "  make restart        - Full down → up cycle"
	@echo ""
	@echo "$(COLOR_BLUE)📊 Observability:$(COLOR_RESET)"
	@echo "  make ps             - Show running service status"
	@echo "  make health         - Check container health states"
	@echo "  make logs           - Tail logs for all services"
	@echo ""
	@echo "  $(COLOR_CYAN)===== While stack is running (new terminal) =====$(COLOR_RESET)"
	@echo "  make shell-prometheus  - Open shell in prometheus container"
	@echo "  make shell-grafana     - Open shell in grafana container"
	@echo ""
	@echo "$(COLOR_YELLOW)🧹 Cleanup:$(COLOR_RESET)"
	@echo "  make prune          - Remove unused Docker resources (prompt)"
	@echo ""
	@echo "$(COLOR_CYAN)Access (SSH tunnel required for remote hosts):$(COLOR_RESET)"
	@echo "  Grafana:     http://localhost:3000"
	@echo "  Portainer:   https://localhost:9443"
	@echo "  Prometheus:  http://localhost:9090  (internal only)"
	@echo ""

# ============================================
# INIT — create required Docker networks
# ============================================
init:
	@chmod +x scripts/init-networks.sh && bash scripts/init-networks.sh

# ============================================
# UP
# ============================================
up:
	@echo "$(COLOR_BOLD)🚀 Starting monitoring stack...$(COLOR_RESET)"
	@echo "$(COLOR_CYAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(COLOR_RESET)"
	@if [ -f $(ENV_FILE) ]; then \
	    export $$(grep -v '^#' $(ENV_FILE) | xargs) 2>/dev/null; \
	fi; \
	if [ -z "$${GF_ADMIN_PASSWORD}" ]; then \
	    echo "$(COLOR_YELLOW)⚠️  GF_ADMIN_PASSWORD not set.$(COLOR_RESET)"; \
	    echo "  cp .env.example .env  and fill in GF_ADMIN_PASSWORD"; \
	    exit 1; \
	fi
	$(COMPOSE) up -d
	@echo "$(COLOR_GREEN)✅ Stack started$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_CYAN)  Grafana   → http://localhost:3000$(COLOR_RESET)"
	@echo "$(COLOR_CYAN)  Portainer → https://localhost:9443$(COLOR_RESET)"

# ============================================
# DOWN
# ============================================
down:
	@echo "$(COLOR_BOLD)🛑 Stopping monitoring stack...$(COLOR_RESET)"
	$(COMPOSE) down
	@echo "$(COLOR_GREEN)✅ Stack stopped$(COLOR_RESET)"

# ============================================
# RESTART
# ============================================
restart: down up

# ============================================
# LOGS
# ============================================
logs:
	@echo "$(COLOR_BOLD)📜 Tailing stack logs (Ctrl+C to stop)...$(COLOR_RESET)"
	$(COMPOSE) logs -f

# ============================================
# PS
# ============================================
ps:
	@echo "$(COLOR_BOLD)📋 Service status$(COLOR_RESET)"
	@echo "$(COLOR_CYAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(COLOR_RESET)"
	$(COMPOSE) ps

# ============================================
# HEALTH
# ============================================
health:
	@echo "$(COLOR_BOLD)🏥 Container health$(COLOR_RESET)"
	@echo "$(COLOR_CYAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(COLOR_RESET)"
	@for cname in monitoring-prometheus monitoring-grafana monitoring-cadvisor \
	              monitoring-pushgateway monitoring-portainer monitoring-node-exporter; do \
	    STATUS=$$(docker inspect --format='{{.State.Status}}' $$cname 2>/dev/null || echo "absent"); \
	    HEALTH=$$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}n/a{{end}}' $$cname 2>/dev/null || echo "absent"); \
	    if [ "$$STATUS" = "running" ]; then \
	        echo "  $(COLOR_GREEN)✅$(COLOR_RESET) $$cname  state=$$STATUS  health=$$HEALTH"; \
	    else \
	        echo "  $(COLOR_YELLOW)⚠️$(COLOR_RESET)  $$cname  state=$$STATUS"; \
	    fi; \
	done
	@echo "$(COLOR_CYAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(COLOR_RESET)"

# ============================================
# SHELL — PROMETHEUS
# ============================================
shell-prometheus:
	@echo "$(COLOR_BOLD)🐚 Opening shell in $(PROM_CONTAINER)...$(COLOR_RESET)"
	docker exec -it $(PROM_CONTAINER) /bin/sh || \
	echo "$(COLOR_YELLOW)⚠️  Container not running. Try: make up$(COLOR_RESET)"

# ============================================
# SHELL — GRAFANA
# ============================================
shell-grafana:
	@echo "$(COLOR_BOLD)🐚 Opening shell in $(GRAFANA_CONTAINER)...$(COLOR_RESET)"
	docker exec -it $(GRAFANA_CONTAINER) /bin/bash || \
	docker exec -it $(GRAFANA_CONTAINER) /bin/sh || \
	echo "$(COLOR_YELLOW)⚠️  Container not running. Try: make up$(COLOR_RESET)"

# ============================================
# PRUNE
# ============================================
prune:
	@echo "$(COLOR_BOLD)🧹 Removing unused Docker resources...$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)⚠️  This will remove:$(COLOR_RESET)"
	@echo "  - Stopped containers"
	@echo "  - Unused networks"
	@echo "  - Dangling images"
	@echo "  - Build cache"
	@echo ""
	@read -p "Continue? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
	    docker system prune -af; \
	    echo "$(COLOR_GREEN)✅ Prune complete$(COLOR_RESET)"; \
	else \
	    echo "$(COLOR_YELLOW)Cancelled$(COLOR_RESET)"; \
	fi
