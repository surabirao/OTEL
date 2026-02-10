# Splunk Enterprise OTEL Integration Role

This role configures Splunk Enterprise to receive and process OpenTelemetry (OTEL) telemetry data through HTTP Event Collector (HEC).

## 📋 Overview

**Splunk Enterprise** is configured to:
- Receive metrics, logs, and traces from OTEL Collector via HTTP Event Collector (HEC)
- Index telemetry data for real-time search and analysis
- Support OTLP (OpenTelemetry Protocol) receivers via gRPC and HTTP
- Process and batch data for efficient ingestion

### Quick Access
- **Splunk Web UI**: http://localhost:8000
- **HEC Receiver**: https://localhost:8088
- **OTEL Collector**: Listens on 4317 (gRPC) & 4318 (HTTP)
- **Default Username**: `admin`
- **Default Password**: `SplunkAdmin123!`

## 📁 Directory Structure

```
splunk-enterprise/
├── configs/
│   ├── hec-config.yaml           # OTEL Collector → Splunk HEC pipeline
│   └── docker-compose.yaml       # Docker orchestration file
├── inputs/
│   └── inputs.conf               # Splunk HEC input configuration & tokens
├── dashboards/                   # Custom dashboards (future)
├── README.md                     # Quick start guide (this file)
├── CONFIGURATION.md              # Detailed configuration reference
└── SETUP.md                      # Step-by-step setup guide (if needed)
```

## ⚙️ Configuration Files

### hec-config.yaml
OTEL Collector configuration that defines:
- **Receivers**: OTLP gRPC (4317) and HTTP (4318) endpoints
- **Processors**: Batching and memory limiting for performance
- **Exporters**: Splunk HEC exporter using authentication tokens
- **Pipelines**: Routes telemetry (metrics, traces, logs) to Splunk

```yaml
# Example pipeline: OTLP → Batch → HEC Export → Splunk
receivers: [otlp]
processors: [memory_limiter, batch]
exporters: [splunk_hec]
```

### inputs.conf (Splunk Configuration)
Splunk server configuration that:
- **Enables HEC**: Port 8088 with SSL/TLS
- **Creates HEC Tokens**: Pre-configured tokens for metrics, logs, traces
- **Sets Data Destination**: Routes data to "main" index
- **Defines Source Types**: Identifies data type for proper processing

```ini
# Three separate tokens for different data types
[http_event_collector_token:otel-metrics-token]
token = 11111111-1111-1111-1111-111111111111
sourcetype = otel:metrics

[http_event_collector_token:otel-logs-token]
token = 22222222-2222-2222-2222-222222222222
sourcetype = otel:logs

[http_event_collector_token:otel-traces-token]
token = 33333333-3333-3333-3333-333333333333
sourcetype = otel:traces
```

### docker-compose.yaml
Complete Docker orchestration file that:
- Starts Splunk Enterprise container with all required ports
- Starts OTEL Collector container
- Mounts configuration files
- Manages networking and volumes
- Ensures containers communicate

## 🚀 Quick Start Guide

### 1. Start Splunk Enterprise & OTEL Collector

Navigate to the splunk-enterprise directory and run Docker Compose:

```bash
cd /workspaces/OTEL/splunk-enterprise

# Pull latest images and start containers
docker-compose up -d

# Verify containers are running
docker-compose ps
```

**Services started:**
- ✅ Splunk Enterprise (Web UI on 8000, HEC on 8088)
- ✅ OTEL Collector (Receivers on 4317/4318)

### 2. Access Splunk Web Console

Open in browser: **http://localhost:8000**

**Login credentials:**
- Username: `admin`
- Password: `SplunkAdmin123!`

### 3. Verify HEC is Working

Send test data to HEC:

```bash
curl -k https://localhost:8088/services/collector \
  -H "Authorization: Splunk 11111111-1111-1111-1111-111111111111" \
  -d '{"event": "test metric", "sourcetype": "test"}'
```

### 4. Send OTEL Data

Configure your application to send telemetry to OTEL Collector:

```bash
# For gRPC (port 4317)
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317

# For HTTP (port 4318)
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318

# Run your instrumented application
python my_app.py  # or your application
```

### 5. Search Splunk for Data

In Splunk Web UI:
1. Click **Search & Reporting**
2. Run search: `index=main sourcetype=otel:*`
3. Set time range to "Last 1 hour"
4. View indexed telemetry data

## 📊 Data Flow Architecture

```
┌─────────────────┐
│  Your App       │
│ (Instrumented)  │
└────────┬────────┘
         │ OTLP (gRPC/HTTP)
         ▼
┌─────────────────────────────┐
│ OTEL Collector              │
│ • Receive metrics/logs/traces│
│ • Batch processing          │
│ • Memory limiting           │
└────────┬────────────────────┘
         │ HEC HTTP POST
         ▼
┌─────────────────────────────┐
│ Splunk Enterprise HEC       │
│ (Port 8088, with token)     │
└────────┬────────────────────┘
         │ Validate & Index
         ▼
┌─────────────────────────────┐
│ Splunk Index Storage        │
│ (main, otel_metrics, etc.)  │
└─────────────────────────────┘
         ▲
         │ SPL Queries
┌────────┴────────────────────┐
│ Splunk Web Console          │
│ (Search & Reporting)        │
└─────────────────────────────┘
```

### 3. Configure HEC Tokens

Update the tokens in `inputs/inputs.conf` with actual tokens from your Splunk instance:

```conf
[http_event_collector_token:otel-collector-token]
token = YOUR_ACTUAL_HEC_TOKEN
```

**To generate a token in Splunk:**
1. Go to **Settings → Data Inputs → HTTP Event Collector**
2. Click **New Token**
3. Enter name: `otel-collector`
4. Click **Next** and select **Index: main**
5. Copy the generated **Token ID**
6. Update `inputs.conf` with that token

### 4. Send Telemetry Data

The OTEL Collector is ready to receive:

**gRPC endpoint** (recommended for performance):
```bash
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317 \
OTEL_EXPORTER_OTLP_HEADERS="signoz-access-token=xxxx" \
python your-app.py
```

**HTTP endpoint**:
```bash
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318 \
node your-app.js
```

## 🔧 HEC Configuration Overview

### What is HEC?
HTTP Event Collector (HEC) is Splunk's primary method for receiving data over HTTP/HTTPS:
- **Secure**: Uses authentication tokens and optional TLS
- **Performant**: Handles high-volume data ingestion
- **Simple**: Just HTTP POST to send data
- **Flexible**: Supports metrics, logs, traces, and custom events

### HEC Default Settings
| Setting | Value |
|---------|-------|
| Port | 8088 |
| Protocol | HTTPS (SSL) |
| Max Connections | Auto-configured |
| Max Event Size | 2MB |
| Default Index | main |

### HEC Tokens Included
| Token Name | Token ID | Purpose |
|------------|----------|---------|
| otel-metrics | 11111111... | For metrics data |
| otel-logs | 22222222... | For log data |
| otel-traces | 33333333... | For trace data |

## ✅ Verification Checklist

- [ ] Docker containers running: `docker-compose ps`
- [ ] Splunk accessible: http://localhost:8000
- [ ] Can login with admin credentials
- [ ] HEC endpoint responding: `curl -k https://localhost:8088`
- [ ] OTEL Collector logs show no errors: Check console output
- [ ] Test data shows in Splunk search results

## 📚 For More Information

- **Detailed Configuration**: See [CONFIGURATION.md](CONFIGURATION.md)
- **Splunk HEC Docs**: https://docs.splunk.com/Documentation/Splunk/latest/Data/HEC
- **OTEL Collector**: https://opentelemetry.io/docs/collector/
- **OTEL Splunk Exporter**: https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/splunkhecexporter
