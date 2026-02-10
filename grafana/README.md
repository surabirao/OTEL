# Grafana Configuration

This directory contains Grafana configuration for OTEL (OpenTelemetry) monitoring and visualization.

## Directory Structure

- **configs/**: Grafana configuration files
- **provisioning/datasources**: Data source configurations (Prometheus, Loki, etc.)
- **provisioning/dashboards**: Dashboard provisioning configurations
- **dashboards/**: Grafana dashboard JSON definitions

## Quick Start

1. **Setup**: Follow [SETUP.md](SETUP.md) for initial configuration
2. **Deployment**: See [DEPLOYMENT.md](DEPLOYMENT.md) for deployment instructions
3. **Configuration**: Review [CONFIGURATION.md](CONFIGURATION.md) for detailed configuration options

## Features

- Auto-provisioned datasources
- Pre-configured dashboards
- Docker Compose support
- OpenTelemetry metrics integration

## Accessing Grafana

After deployment, Grafana will be available at:
- **URL**: http://localhost:3000
- **Default Username**: admin
- **Default Password**: admin (change on first login)
