# Grafana Configuration Reference

## Configuration Sections

### Authentication

- Admin User: admin
- Default Auth Provider: Local Grafana Authentication
- LDAP, OAuth2, and SAML available for enterprise deployments

### Database

- Default: SQLite (suitable for development/testing)
- Production: PostgreSQL recommended
- MySQL/MariaDB also supported

### Data Sources

Grafana can connect to multiple data sources:

#### Prometheus
- URL: http://prometheus:9090
- Type: Prometheus
- Scrape Interval: 15s (configurable)

#### Loki
- URL: http://loki:3100
- Type: Loki
- For log aggregation

#### OpenTelemetry
- Metrics via Prometheus
- Traces via Jaeger/Tempo
- Logs via Loki

### Alerting

- Configure alert rules in datasource
- Notification channels: Email, Slack, PagerDuty, etc.
- Alert evaluation interval: 1m (default)

### Users & Teams

- Manage users in Admin > Users
- Create teams for multi-tenant setups
- Configure role-based access control (RBAC)

### Plugins

Install additional plugins:

```bash
docker exec grafana grafana-cli plugins install grafana-piechart-panel
```

### Security

- Enable HTTPS: Configure in grafana-config.ini
- API tokens: Create under Admin > API Tokens
- Cross-Origin Resource Sharing (CORS): Configure as needed

## Performance Tuning

- Set appropriate scrape intervals
- Configure retention policies
- Use query caching for frequently accessed dashboards

## Backup & Recovery

- Backup database: `docker exec grafana grafana-cli admin export-dashboard`
- Export dashboards as JSON
- Version control dashboard JSON files
