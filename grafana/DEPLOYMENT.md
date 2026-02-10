# Grafana Deployment Guide

## Deployment Options

### 1. Docker Compose (Development/Testing)

Deploy using docker-compose:

```bash
cd /workspaces/OTEL/grafana
docker-compose -f configs/docker-compose.yaml up -d
```

Check status:
```bash
docker-compose -f configs/docker-compose.yaml ps
```

Stop:
```bash
docker-compose -f configs/docker-compose.yaml down
```

### 2. Kubernetes (Production)

For Kubernetes deployments, consider using:
- Grafana Helm Chart
- Kustomize overlays
- Custom manifests

### 3. Standalone Binary

Download from https://grafana.com/grafana/download and configure manually.

## Environment Variables

Configure Grafana via environment variables:

```bash
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=secure_password
GF_USERS_ALLOW_SIGN_UP=false
GF_DATABASE_TYPE=postgres
GF_DATABASE_HOST=db:5432
```

## Data Persistence

### Docker

Mount volumes for data persistence:

```yaml
volumes:
  - grafana_storage:/var/lib/grafana
  - ./provisioning:/etc/grafana/provisioning
  - ./dashboards:/var/lib/grafana/dashboards
```

### Kubernetes

Use PersistentVolumeClaims (PVCs) for persistent storage.

## Health Checks

Grafana health endpoint: `http://localhost:3000/api/health`

## Monitoring Grafana

Monitor Grafana metrics:
- CPU and memory usage
- Active sessions
- Query performance
- Plugin status

## Scaling Considerations

- Use external database for multi-instance setups
- Configure shared storage for provisioning files
- Load balance with nginx/haproxy
- Use session store for distributed setups

## Security Deployment

1. Change default admin password
2. Enable HTTPS/TLS
3. Configure authentication provider
4. Restrict API access
5. Enable RBAC for users
6. Audit log configuration

## Updates & Upgrades

1. Backup Grafana database
2. Back up provisioning files
3. Update Docker image tag
4. Test in staging environment
5. Deploy to production

## Troubleshooting Deployment

- Check logs: `docker logs grafana`
- Verify network connectivity to data sources
- Confirm volume mounts
- Check resource limits
- Review configuration file syntax
