# Monitoring Stack — Getting Started

Prometheus · Grafana · cAdvisor · node-exporter · Pushgateway · Portainer

---

## Prerequisites

### 1 — Docker networks

Both external networks must exist before `make up`.

```bash
# First-time only (idempotent — safe to re-run)
make init

# Verify
docker network ls | grep -E "proxy-network|backend-chatbot-network"
```

> `proxy-network` is normally created by the reverse-proxy stack; `make init`
> here is a fallback so this repo can also stand up on its own.

### 2 — Grafana admin password

```bash
cp .env.example .env
# edit .env and set GF_ADMIN_PASSWORD to a strong password
```

The `make up` target and `docker compose` both abort with a clear error if
`GF_ADMIN_PASSWORD` is unset or empty.

---

## First run

```bash
cd ~/monitoring

# Pull all images (optional — up does this automatically)
docker compose pull

# Start the stack
make up
# or: GF_ADMIN_PASSWORD=<pass> make up
```

Expected output from `make health` once all containers are stable (≈ 30 s):

```
✅  monitoring-prometheus       state=running  health=n/a
✅  monitoring-grafana          state=running  health=n/a
✅  monitoring-cadvisor         state=running  health=n/a
✅  monitoring-pushgateway      state=running  health=n/a
✅  monitoring-portainer        state=running  health=n/a
✅  monitoring-node-exporter    state=running  health=n/a
```

> `node-exporter` runs with `network_mode: host` so it will not appear in
> `docker compose ps` but `docker ps | grep node-exporter` shows it.

---

## Access (SSH tunnel required from a remote machine)

| Service | Internal URL | SSH tunnel command |
|---|---|---|
| Grafana | `http://localhost:3000` | `ssh -L 3000:localhost:3000 user@server` |
| Portainer | `https://localhost:9443` | `ssh -L 9443:localhost:9443 user@server` |
| Prometheus | `http://localhost:9090` | `ssh -L 9090:localhost:9090 user@server` |
| Pushgateway | `http://localhost:9091` | `ssh -L 9091:localhost:9091 user@server` |

---

## Verify Prometheus targets

After `make up`, open `http://localhost:9090/targets`:

| Job | Expected state |
|---|---|
| `node-exporter` | **UP** |
| `cadvisor` | **UP** |
| `chatbot-api` | DOWN — pending Session B |
| `nginx-exporter` | DOWN — pending Session B |
| `pushgateway` | DOWN — pending Session C |

---

## Session A checkpoint

Before any Session B work, confirm all of the following:

- [ ] `make health` — all 6 containers running
- [ ] Prometheus `/targets` — `node-exporter` + `cadvisor` **UP**
- [ ] Grafana — **Infrastructure Overview** dashboard shows CPU, RAM, disk, network panels populated
- [ ] Grafana — **Container Metrics** dashboard shows per-container RSS, throttle, network drops
- [ ] Grafana — **Application Metrics** and **Business Metrics** dashboards visible with "pending" text
- [ ] Portainer reachable at `https://localhost:9443` via SSH tunnel
- [ ] Admin-panel regression: `docker exec reverse-proxy-nginx-1 curl -sf http://admin-panel:3001/health` → `healthy`
- [ ] Observability card visible in admin-panel SPA after login as superAdmin

---

## Common operations

```bash
make up                 # Start stack (requires GF_ADMIN_PASSWORD in env or .env)
make down               # Stop and remove containers (volumes preserved)
make restart            # down → up
make logs               # Tail all service logs
make ps                 # docker compose ps
make health             # Per-container state summary
make shell-prometheus   # /bin/sh in prometheus container
make shell-grafana      # /bin/bash in grafana container
make prune              # docker system prune -af (confirmation required)
```

---

## Image versions (pinned)

| Service | Image |
|---|---|
| Prometheus | `prom/prometheus:v3.13.2` |
| Grafana | `grafana/grafana:13.0.6` |
| node-exporter | `prom/node-exporter:v1.12.1` |
| cAdvisor | `gcr.io/cadvisor/cadvisor:v0.55.1` |
| Pushgateway | `prom/pushgateway:v1.9.0` |
| Portainer | `portainer/portainer-ce:2.44.0` |


## Troubleshooting

### `manifest unknown` on `make up`

A pinned image tag no longer exists on the registry.  Run:

```bash
docker compose pull 2>&1 | grep Error
```

Check the current tag list:
```bash
curl -s "https://registry.hub.docker.com/v2/repositories/prom/prometheus/tags/?page_size=10&ordering=last_updated" \
  | python3 -c "import json,sys; [print(t['name']) for t in json.load(sys.stdin)['results']]"
```

Update the relevant image tag in `docker-compose.yml` and re-run `make up`.

### `network proxy-network not found`

```bash
make init
```

### Grafana dashboards empty / "No data"

Prometheus must be scraping for at least one interval (15 s) before panels
populate.  Check `http://localhost:9090/targets` to confirm `node-exporter` and
`cadvisor` are **UP**.

### `GF_ADMIN_PASSWORD must be set`

```bash
export GF_ADMIN_PASSWORD=<your-password>
make up
# or add it to .env
```
