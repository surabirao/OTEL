# Splunk Enterprise Configuration Guide

This document provides detailed configuration information for Splunk Enterprise in the OTEL integration.

## Splunk Enterprise Setup

### Installation Method
Splunk Enterprise is deployed using Docker containers for easy setup and management.

```bash
# Start Splunk Enterprise
docker run -d --name splunk \
  -p 8000:8000 \
  -p 8088:8088 \
  -p 8089:8089 \
  -e SPLUNK_START_ARGS='--accept-license' \
  -e SPLUNK_GENERAL_TERMS='--accept-sgt-current-at-splunk-com' \
  -e SPLUNK_PASSWORD='SplunkAdmin123!' \
  splunk/splunk:latest
```

### Default Credentials
- **Username**: `admin`
- **Password**: `SplunkAdmin123!`
- **Web Console**: http://localhost:8000

### Network Ports
| Port | Service | Purpose |
|------|---------|---------|
| 8000 | Web UI | Splunk Web Console |
| 8088 | HEC | HTTP Event Collector (Data Input) |
| 8089 | Management | Splunk Management Port |
| 9997 | Splunk TCP | Splunk-to-Splunk Communication |

## HTTP Event Collector (HEC) Configuration

### What is HEC?
HTTP Event Collector (HEC) is Splunk's primary method for receiving data over HTTP/HTTPS. It's commonly used for:
- Collecting logs from applications and services
- Receiving metrics and events
- Ingesting OpenTelemetry data

### How HEC Works

```
Application/OTEL Collector
        ↓ (HTTP POST)
  HEC Endpoint (port 8088)
        ↓
  Splunk Internal Queue
        ↓
  Parsing & Indexing
        ↓
  Splunk Index (main)
```

### HEC Token Setup

Create HEC tokens in Splunk for authentication:

**Via Web UI:**
1. Navigate to **Settings → Data Inputs → HTTP Event Collector**
2. Click **New Token**
3. Enter **Name**: `otel-metrics-token`
4. Click **Next** and select **Index: main**
5. Copy the generated **Token Value**

**Via CLI:**
```bash
docker exec splunk /opt/splunk/bin/splunk http-event-collector create \
  otel-metrics-token \
  -default_index main \
  -auth admin:SplunkAdmin123!
```

### HEC Configuration Parameters

```yaml
# HEC Endpoint Configuration
endpoint: "https://localhost:8088/services/collector"
token: "YOUR_HEC_TOKEN_HERE"
source: "otel/collector"
sourcetype: "otel:metrics"
index: "main"

# Security Settings
insecure_skip_verify: true  # For self-signed certificates (dev only!)
ca_file: "/path/to/ca.crt"  # Production: Use proper certificates

# Performance Settings
max_content_length_logs: 2097152  # 2MB max per event
```

## Configuring Data Input

### Enable HEC in Splunk

**File: inputs.conf**
```ini
[http_event_collector]
disabled = false
port = 8088
enableSSL = true
```

**Location**: `/opt/splunk/etc/system/local/inputs.conf`

### Create HEC Data Channels

```ini
# Metrics Channel
[http_event_collector_token:otel-metrics-token]
disabled = false
token = 11111111-1111-1111-1111-111111111111
index = main
sourcetype = otel:metrics

# Logs Channel
[http_event_collector_token:otel-logs-token]
disabled = false
token = 22222222-2222-2222-2222-222222222222
index = main
sourcetype = otel:logs

# Traces Channel
[http_event_collector_token:otel-traces-token]
disabled = false
token = 33333333-3333-3333-3333-333333333333
index = main
sourcetype = otel:traces
```

## OTEL Collector Configuration for HEC

### OTEL Collector Pipeline

```yaml
# OpenTelemetry Collector Configuration
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: "0.0.0.0:4317"
      http:
        endpoint: "0.0.0.0:4318"

processors:
  batch:
    send_batch_size: 256
    timeout: 10s
  
  memory_limiter:
    check_interval: 1s
    limit_mib: 512

exporters:
  splunk_hec:
    endpoint: "https://localhost:8088/services/collector"
    token: "YOUR_HEC_TOKEN"
    source: "otel/collector"
    sourcetype: "otel:metrics"
    index: "main"
    insecure_skip_verify: true

service:
  pipelines:
    metrics:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [splunk_hec]
```

### OTEL Collector Data Flow

```
Your Application (instrument with OTEL SDK)
        ↓
OTEL Collector (receives on 4317/4318)
        ↓
Batch Processor (batches data)
        ↓
Memory Limiter (controls memory usage)
        ↓
Splunk HEC Exporter
        ↓
Splunk Enterprise (port 8088)
        ↓
Indexed Data in "main" index
```

## Index Configuration

### Default Index: "main"

Splunk stores all incoming HEC data in the **"main"** index by default.

**View incoming data:**
1. Open Splunk Web UI: http://localhost:8000
2. Click **Search & Reporting**
3. Run search: `index=main sourcetype=otel:*`
4. Set Time range to "Last 1 hour"

### Create Custom Index

**Via CLI:**
```bash
docker exec splunk /opt/splunk/bin/splunk add index otel_metrics \
  -auth admin:SplunkAdmin123!
```

**Via UI:**
1. **Settings → Indexes**
2. Click **New Index**
3. Enter name: `otel_metrics`
4. Set max KB to 100000 (100GB)
5. Save

### Update HEC Token to Use Custom Index

```ini
[http_event_collector_token:otel-metrics-token]
token = YOUR_TOKEN
outputgroup = otel_metrics_group
```

## Data Validation

### Send Test Data to HEC

```bash
curl -k https://localhost:8088/services/collector \
  -H "Authorization: Splunk YOUR_HEC_TOKEN" \
  -d '{
    "event": "test event",
    "sourcetype": "test",
    "source": "test_source",
    "index": "main"
  }'
```

### Search for Data

In Splunk Web UI:
```
index=main earliest=-1h
```

Or search by source type:
```
sourcetype=otel:metrics earliest=-1h
```

## Performance Tuning

### Increase HEC Throughput

```ini
[http_event_collector]
disabled = false
port = 8088
enableSSL = true
maxSockets = 100
maxSockets_auto = true
persistentQueueSize = 100MB
```

### HEC Load Balancing

For high volume, distribute load across multiple HEC receivers:

```yaml
exporters:
  splunk_hec:
    endpoint: "https://splunk-hec-1:8088/services/collector"
    token: "token1"
  splunk_hec/secondary:
    endpoint: "https://splunk-hec-2:8088/services/collector"
    token: "token2"

service:
  pipelines:
    metrics:
      exporters: [splunk_hec, splunk_hec/secondary]
```

## SSL/TLS Configuration

### For Production

1. **Generate Certificates:**
```bash
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365
```

2. **Configure in inputs.conf:**
```ini
[http_event_collector]
serverCert = /opt/splunk/etc/auth/mycerts/server.pem
enableSSL = true
```

3. **Use in OTEL Collector:**
```yaml
exporters:
  splunk_hec:
    endpoint: "https://localhost:8088/services/collector"
    ca_file: "/path/to/ca.crt"
    insecure_skip_verify: false
```

## Troubleshooting

### Check HEC Status

```bash
# Test HEC endpoint
curl -k https://localhost:8088 \
  -H "Authorization: Splunk YOUR_TOKEN" \
  -d '{"event":"test"}'
```

### View HEC Metrics

In Splunk Web:
```
index=_internal group=http_event_collector
```

### Common Issues

| Issue | Solution |
|-------|----------|
| 401 Unauthorized | Invalid HEC token |
| 503 Service Unavailable | Splunk indexer queue full |
| Connection refused | Port 8088 not open |
| SSL certificate error | Use `insecure_skip_verify: true` (dev) or proper certificates (prod) |

## Next Steps

1. **Create Dashboards**: Visualize OTEL metrics in Splunk
2. **Set Up Alerts**: Create alerts for anomalies
3. **Configure Forwarders**: Scale data collection
4. **Implement RBAC**: Set up users and roles
5. **Enable Encryption**: Use proper SSL/TLS in production
