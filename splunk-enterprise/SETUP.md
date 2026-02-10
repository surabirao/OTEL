# Splunk Enterprise Setup Guide

Complete step-by-step instructions for setting up Splunk Enterprise with OTEL integration.

## Prerequisites

- Docker installed and running
- Docker Compose v1.29+
- At least 4GB available RAM
- Ports 8000, 8088, 8089, 4317, 4318 available

## Installation Steps

### Step 1: Navigate to the Role Directory

```bash
cd /workspaces/OTEL/splunk-enterprise
```

Verify the directory structure:
```bash
ls -la
# Output should show:
# configs/  inputs/  dashboards/  README.md  CONFIGURATION.md  SETUP.md
```

### Step 2: Start Splunk & OTEL Services

Pull latest Docker images and start services:

```bash
docker-compose up -d
```

This command:
- Pulls the latest Splunk Enterprise image
- Pulls the latest OTEL Collector image
- Starts both services with proper networking
- Mounts configuration files
- Sets environment variables

### Step 3: Wait for Splunk to Initialize

Splunk needs time for initial setup (2-3 minutes):

```bash
# Watch initialization progress
docker-compose logs -f splunk

# Expected output after initialization:
# splunk | Ansible playbook complete, will begin streaming splunkd_stderr.log
```

Press Ctrl+C when you see the "playbook complete" message.

### Step 4: Verify Services Are Running

```bash
# Check container status
docker-compose ps

# Should show:
# SERVICE         STATUS              PORTS
# splunk          Up (healthy)        0.0.0.0:8000->8000/tcp
# otel-collector  Up                  0.0.0.0:4317->4317/tcp
```

### Step 5: Access Splunk Web Console

Open your browser and navigate to: **http://localhost:8000**

Login with:
- **Username**: `admin`
- **Password**: `SplunkAdmin123!`

> **Note**: If page doesn't load immediately, wait 10-15 more seconds for Splunk initialization.

## Post-Installation Configuration

### Step 6: Verify HEC is Enabled

1. In Splunk Web Console, click **Settings** (top-right user menu)
2. Select **Data Inputs**
3. Click **HTTP Event Collector**
4. Verify status shows "Enabled"

### Step 7: Create or Verify HEC Token

**Option A: Use Existing Token**
The pre-configured token in `inputs/inputs.conf` should work:
```
11111111-1111-1111-1111-111111111111
```

**Option B: Create New Token**
1. In Splunk Web: **Settings → Data Inputs → HTTP Event Collector**
2. Click **New Token**
3. Enter name: `otel-metrics-production`
4. Set source type: `_json`, `otel:metrics`, or choose from list
5. Click **Next**
6. Select Index: `main` (or create custom index)
7. Review settings and click **Done**
8. **Copy the Token Value** shown in green
9. Update `inputs/inputs.conf` with new token

### Step 8: Test HEC Connectivity

Send a test event to verify HEC is working:

```bash
TOKEN="11111111-1111-1111-1111-111111111111"

curl -k -X POST https://localhost:8088/services/collector \
  -H "Authorization: Splunk $TOKEN" \
  -d '{
    "event": "Test OTEL Integration",
    "sourcetype": "test:event",
    "source": "test_source",
    "index": "main"
  }'
```

**Expected response:**
```json
{
  "text": "Success",
  "code": 0
}
```

### Step 9: Verify Data in Splunk

1. In Splunk Web, click **Search & Reporting**
2. Run this search: `index=main sourcetype=test:event`
3. You should see your test event appear
4. Set time range to "Last 1 hour" if needed

## OTEL Collector Configuration

### Step 10: Configure OTEL Receiver

The OTEL Collector listens on:
- **gRPC**: `localhost:4317` (recommended)
- **HTTP**: `localhost:4318`

**File**: `configs/hec-config.yaml`

### Step 11: Test OTEL Collector

Send test telemetry data:

```bash
# Using grpcurl to test gRPC endpoint
grpcurl -plaintext -d '{}' localhost:4317 list

# Or test HTTP endpoint
curl -X POST http://localhost:4318/v1/metrics \
  -H "Content-Type: application/json" \
  -d '{"resourceMetrics": []}'
```

### Step 12: Configure Your Application

**For Python applications:**
```python
from opentelemetry import metrics
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader

exporter = OTLPMetricExporter(endpoint="localhost:4317")
reader = PeriodicExportingMetricReader(exporter)
provider = MeterProvider(metric_readers=[reader])
metrics.set_meter_provider(provider)

meter = metrics.get_meter(__name__)
counter = meter.create_counter("app.counter")
counter.add(1)
```

**For Node.js applications:**
```javascript
const { MeterProvider, PeriodicExportingMetricReader } = require("@opentelemetry/sdk-metrics");
const { OTLPMetricExporter } = require("@opentelemetry/exporter-trace-otlp-grpc");

const exporter = new OTLPMetricExporter({ url: "http://localhost:4317" });
const reader = new PeriodicExportingMetricReader({ exporter });
const meterProvider = new MeterProvider({ readers: [reader] });
```

**Using environment variables:**
```bash
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
export OTEL_EXPORTER_OTLP_HEADERS="signoz-access-token=optional"
export OTEL_SDK_DISABLED=false

python my_app.py
```

## Troubleshooting

### Issue: Splunk Web Console Won't Load

**Solution:**
```bash
# Check if container is running
docker ps | grep splunk

# If not running, check logs
docker logs splunk

# If it exited, check detailed logs
docker compose logs splunk

# Restart if needed
docker compose down
docker compose up -d
```

### Issue: HEC Connection Refused (curl returns error)

**Solution:**
```bash
# 1. Verify port is listening
netstat -tuln | grep 8088

# 2. Check if port is reachable from inside container
docker exec otel-collector curl -k https://splunk:8088 \
  -H "Authorization: Splunk YOUR_TOKEN"

# 3. Verify HEC is enabled in Splunk UI
# Settings → Data Inputs → HTTP Event Collector
```

### Issue: Test Data Doesn't Appear in Splunk

**Solution:**
1. Verify HEC token is correct: `Settings → Data Inputs → HTTP Event Collector`
2. Check token matches in OTEL config: `configs/hec-config.yaml`
3. View ingestion logs: `index=_internal group=http_event_collector sourcetype=splunkd`
4. Check for parsing errors: `index=main earliest=-10m`

### Issue: OTEL Collector Not Receiving Data from Application

**Solution:**
```bash
# 1. Check OTEL collector is running
docker ps | grep otel-collector

# 2. View collector logs
docker compose logs otel-collector

# 3. Verify OTLP endpoint is accessible
curl -X OPTIONS http://localhost:4318/v1/metrics

# 4. Check firewall/network
docker exec your-app curl -X POST http://otel-collector:4317 -v
```

### Issue: High Memory Usage

**Solution:**
Increase memory limits in `docker-compose.yaml`:
```yaml
services:
  splunk:
    environment:
      - _JAVA_OPTIONS="-Xmx2g -Xms1g"
      - SPLUNK_INSTALL_SENTINEL=-d
```

## Performance Optimization

### For Development Environment

No changes needed - default configuration is suitable.

### For High-Volume Production

1. **Increase Splunk Memory**:
```yaml
splunk:
  environment:
    - _JAVA_OPTIONS="-Xmx4g -Xms2g"
```

2. **Optimize OTEL Collector**:
```yaml
receivers:
  otlp:
    protocols:
      grpc:
        max_recv_msg_size_in_bytes: 20971520  # 20MB
```

3. **Load Balancing**: Add multiple HEC receivers behind a reverse proxy

## Security Hardening

### For Production:

1. **Change Default Password**:
```bash
docker exec splunk /opt/splunk/bin/splunk edit user admin \
  -auth admin:SplunkAdmin123! \
  -password NEW_STRONG_PASSWORD
```

2. **Generate Self-Signed Certificates**:
```bash
openssl req -x509 -newkey rsa:2048 \
  -keyout server.key -out server.crt -days 365

docker cp server.crt splunk:/opt/splunk/etc/auth/mycerts/
docker cp server.key splunk:/opt/splunk/etc/auth/mycerts/
```

3. **Enable Strict SSL**:
Update `configs/hec-config.yaml`:
```yaml
exporters:
  splunk_hec:
    insecure_skip_verify: false
    ca_file: /path/to/ca.crt
```

4. **Implement Network Policies**: Use Docker networks and firewall rules

## Cleanup & Removal

To stop services:
```bash
docker-compose down
```

To remove all data (fresh start):
```bash
docker-compose down -v
```

To remove images:
```bash
docker rmi splunk/splunk:latest otel/opentelemetry-collector:latest
```

## Next Steps

1. ✅ [Read Configuration Guide](CONFIGURATION.md) for detailed settings
2. ✅ Create custom dashboards for your metrics
3. ✅ Set up alerts for anomaly detection
4. ✅ Configure data retention policies
5. ✅ Implement role-based access control (RBAC)
6. ✅ Scale to production with Kubernetes

## Support & Documentation

- Splunk Documentation: https://docs.splunk.com/
- OTEL Collector: https://opentelemetry.io/docs/collector/
- OTEL Splunk Exporter: https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/splunkhecexporter
- Docker Compose Reference: https://docs.docker.com/compose/reference/
