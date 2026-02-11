Splunk OTEL
=============

This folder provides a minimal Docker Compose setup and Otel Collector configuration to send telemetry to the local Splunk Enterprise HEC receiver (assumes the `splunk-enterprise` stack is available on the same Docker network `otel-network`).

Files:
- `docker-compose.yaml` - starts `splunk-otel-collector` using the config below
- `configs/otel-collector-config.yaml` - collector configuration with a Splunk HEC exporter

Quick start:

1. Ensure the `splunk-enterprise` stack is running and the Docker network `otel-network` exists.
2. From this directory run:

```bash
docker compose up -d
```

3. The collector listens on OTLP ports `4317` (gRPC) and `4318` (HTTP).

Update the HEC token and endpoint in `configs/otel-collector-config.yaml` if needed.
