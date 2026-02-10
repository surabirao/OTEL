# Grafana Setup Guide

## Prerequisites

- Docker and Docker Compose installed
- Port 3000 available (default Grafana port)
- OpenTelemetry Collector running (for metrics collection)

## Installation Steps

### 1. Basic Setup

The Grafana configuration is set up in the standard directory structure:

```
grafana/
├── configs/              # Grafana configuration files
├── provisioning/         # Auto-provisioning configurations
│   ├── datasources/      # Data source definitions
│   └── dashboards/       # Dashboard configurations
└── dashboards/           # Dashboard JSON files
```

### 2. Using Docker Compose

Deploy Grafana using the provided docker-compose configuration:

```bash
docker-compose -f configs/docker-compose.yaml up -d
```

### 3. Initialize Grafana

1. Open http://localhost:3000
2. Login with default credentials (admin/admin)
3. Change the default password
4. Configure datasources if not auto-provisioned

### 4. Add Data Sources

Data sources can be added:
- Automatically via provisioning files in `provisioning/datasources/`
- Manually via the Grafana UI

## Configuration Files

- **grafana-config.ini**: Main Grafana configuration
- **datasources.yaml**: Prometheus, Loki, and other data sources
- **dashboards.yaml**: Dashboard provisioning settings

## Troubleshooting

- Check logs: `docker logs grafana_container_name`
- Verify port availability: `netstat -an | grep 3000`
- Ensure volumes are mounted correctly in docker-compose configuration
