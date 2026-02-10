# Splunk Enterprise Deployment Guide

Different deployment options for Splunk Enterprise with OTEL integration.

## Table of Contents

1. [Development Deployment](#development-deployment)
2. [Production Deployment](#production-deployment)
3. [Kubernetes Deployment](#kubernetes-deployment)
4. [Scalability Considerations](#scalability-considerations)

## Development Deployment

### Docker Compose (Current Setup)

Perfect for:
- Local development and testing
- Learning OTEL and Splunk integration
- Small-scale prototyping

**Start Command:**
```bash
docker-compose up -d
```

**Pros:**
- ✅ Quick setup (< 5 minutes)
- ✅ All-in-one environment
- ✅ Easy to modify and test
- ✅ Low resource requirements

**Cons:**
- ❌ Not suitable for production
- ❌ Data lost on container restart
- ❌ Limited scalability
- ❌ No backup capabilities

**Resource Requirements:**
- RAM: 4GB minimum
- CPU: 2 cores minimum
- Disk: 10GB minimal storage

## Production Deployment

### Splunk Enterprise on EC2/Cloud VM

**Architecture:**
```
Internet
    ↓
Load Balancer
    ↓
Splunk Enterprise Instance
    ├── Indexer (processes data)
    └── Search Head (analytics)
    ↓
Persistent Storage (EBS/Volume)
```

**Installation Steps:**

1. **Provision Instance:**
```bash
# AWS Example
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t3.xlarge \
  --key-name your-key \
  --security-groups splunk-security-group \
  --block-device-mappings DeviceName=/dev/xvda,Ebs={VolumeSize=500,VolumeType=gp2}
```

2. **Install Splunk:**
```bash
# Download
wget -O splunk-9.0.1-linux-2.6.23-generic-x86_64.tgz \
  'https://www.splunk.com/bin/splunk/TA_4b0b3586c4fe11eba41d86e5b8e5e8e9/splunk-enterprise'

# Extract
tar xvzf splunk*.tgz -C /opt

# Start with license
cd /opt/splunk
bin/splunk start --accept-license --seed-passwd AdminPassword123
```

3. **Configure for OTEL:**
```bash
# Copy configurations
cp /workspaces/OTEL/splunk-enterprise/inputs/inputs.conf \
  /opt/splunk/etc/system/local/

# Generate HEC token
bin/splunk http-event-collector create otel-production \
  -default_index main \
  -auth admin:ChangeMePassword
```

4. **Enable Persistence:**
```bash
# Configure index storage
cat >> /opt/splunk/etc/system/local/indexes.conf << EOF
[main]
maxKB = 5000000
homePath = volume:main/\$_internal_name
coldPath = volume:cold/\$_internal_name
thawedPath = volume:thawed/\$_internal_name

[volume:main]
storageType = remote
remote.url = s3://your-bucket/splunk/main

[volume:cold]
storageType = remote
remote.url = s3://your-bucket/splunk/cold
EOF
```

**Pros:**
- ✅ Suitable for production
- ✅ Scalable infrastructure
- ✅ Persistent storage
- ✅ Backup support
- ✅ SSL/TLS ready

**Cons:**
- ❌ Complex infrastructure
- ❌ Higher cost
- ❌ Requires capacity planning
- ❌ Manual updates

**Estimated Costs (AWS):**
- t3.xlarge EC2: ~$350/month
- 500GB EBS: ~$50/month
- Data ingestion: ~$0.04 per GB
- **Total**: $400-500/month base + data costs

### Splunk Enterprise with Distributed Indexing

For high-volume environments:

```
OTEL Collectors
    ↓ (HEC)
Load Balancer (TCP 8088)
    ├─ Indexer 1 (Splunk)
    ├─ Indexer 2 (Splunk)
    └─ Indexer 3 (Splunk)
    ↓
Cluster Manager
    │
Search Head Cluster
    ├─ Search Head 1
    ├─ Search Head 2
    └─ Search Head 3
    ↓
Persistent Storage (S3/NFS)
```

**Configuration Example:**
```ini
# indexer-cluster.conf
[indexer_discovery]
pass4SymmKey = your-secret-key
master_uri = https://cluster-master:8089
cxn_timeout = 300
heartbeat_timeout = 60

[replication]
factor = 3
```

## Kubernetes Deployment

### Helm Chart Installation

**Prerequisites:**
- Kubernetes cluster (1.20+)
- Helm 3.x
- Storage class configured

**Installation:**
```bash
# Add Splunk Helm repo
helm repo add splunk https://splunk.github.io/splunk-operator/
helm repo update

# Create namespace
kubectl create namespace splunk

# Install Splunk Operator
helm install splunk-operator splunk/splunk-operator \
  --namespace splunk

# Deploy Splunk Enterprise
cat > splunk-values.yaml << EOF
splunkEnterprise:
  replicas: 1
  image:
    repository: splunk/splunk:latest
  
  password:
    secretRef:
      name: splunk-secrets
      key: password
  
  volumes:
    - name: splunk-data
      persistentVolumeClaim:
        claimName: splunk-pvc
  
  resources:
    requests:
      cpu: "2"
      memory: "4Gi"
    limits:
      cpu: "4"
      memory: "8Gi"

service:
  type: LoadBalancer
  ports:
    - port: 8000
      name: web
    - port: 8088
      name: hec
    - port: 8089
      name: management
EOF

helm install splunk splunk/splunk \
  --namespace splunk \
  -f splunk-values.yaml
```

**Deploy OTEL Collector as DaemonSet:**
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: otel-collector
  namespace: splunk
spec:
  selector:
    matchLabels:
      app: otel-collector
  template:
    metadata:
      labels:
        app: otel-collector
    spec:
      containers:
      - name: otel-collector
        image: otel/opentelemetry-collector:latest
        ports:
        - containerPort: 4317
          name: otlp-grpc
        - containerPort: 4318
          name: otlp-http
        volumeMounts:
        - name: config
          mountPath: /etc/otel-collector-config.yaml
          subPath: config.yaml
        env:
        - name: GOGC
          value: "80"
      volumes:
      - name: config
        configMap:
          name: otel-config
```

**Pros:**
- ✅ Highly scalable
- ✅ Auto-scaling support
- ✅ Container-native
- ✅ Easy updates and rollbacks
- ✅ Multi-region support

**Cons:**
- ❌ Complex infrastructure
- ❌ Requires Kubernetes expertise
- ❌ Higher operational overhead
- ❌ Debugging more complex

**Cost Estimate (AWS EKS):**
- EKS control plane: $73/month
- Node instances (3x t3.xlarge): ~$1050/month
- Storage: ~$100/month
- **Total**: ~$1200/month base + data

## Scalability Considerations

### Ingestion Rate Planning

**Data Volume Estimates:**

| Metric Type | Size per Event | Daily Volume (1K RPS) |
|------------|----------------|----------------------|
| Metrics | 0.5 KB | 43 GB |
| Logs | 1 KB | 86 GB |
| Traces | 2 KB | 172 GB |

**For 10K RPS (production scale):**
- Total daily ingestion: 1+ TB/day
- Monthly storage: 30+ TB
- Recommended: Distributed indexing with 10+ indexers

### Capacity Planning

```
Storage = (Daily Volume in GB) × (Retention Days)

Example:
- 500 GB/day ingestion
- 30 day retention
- Storage = 500 × 30 = 15 TB

With 3x replication for HA:
- Total = 45 TB required
```

### Load Balancing Configuration

**HAProxy Example:**
```
frontend hec_in
    bind *:8088
    default_backend hec_backends
    mode tcp
    balance roundrobin

backend hec_backends
    mode tcp
    server splunk1 10.0.1.10:8088
    server splunk2 10.0.1.11:8088
    server splunk3 10.0.1.12:8088
```

## Migration Path

### Stage 1: Development (Your Current Setup)
- Uses Docker Compose
- Single Splunk instance
- No replication
- **Duration**: 2-4 weeks

### Stage 2: Staging (Pre-Production)
- Upgraded instance (t3.large minimum)
- SSL/TLS certificates
- Daily backups
- Load testing
- **Duration**: 4-8 weeks

### Stage 3: Production
- Distributed indexing
- Search head cluster
- SSL/TLS everywhere
- Redundancy and backups
- **Duration**: Ongoing

### Stage 4: Enterprise Scale (Optional)
- Kubernetes deployment
- Multi-region setup
- Advanced monitoring
- 99.99% availability
- **Duration**: 3-6 months

## Backup & Disaster Recovery

### Automated Backups (Production)

```bash
# Daily backup script
#!/bin/bash
BACKUP_DIR="/backups/splunk"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Backup Splunk configuration
tar -czf $BACKUP_DIR/splunk-config-$TIMESTAMP.tar.gz \
  /opt/splunk/etc/

# Backup to S3
aws s3 cp $BACKUP_DIR/ s3://my-bucket/splunk-backups/
```

**Recovery (if needed):**
```bash
# Restore configuration
tar -xzf splunk-config-*.tar.gz -C /opt/splunk/etc/

# Restart Splunk
/opt/splunk/bin/splunk start --accept-license
```

## Recommended Setup by Use Case

### Learning & Development
→ Use current **Docker Compose** setup

### Small Team (< 100GB/day)
→ Single **EC2 instance** (t3.xlarge)

### Medium Team (100GB-1TB/day)
→ **Distributed indexing** (3 indexers, 1 search head)

### Large Enterprise (> 1TB/day)
→ **Kubernetes cluster** with auto-scaling

---

**Need Help?**
- Splunk Professional Services: https://www.splunk.com/en_us/services-and-support/professional-services.html
- Community Forum: https://community.splunk.com/
- Documentation: https://docs.splunk.com/
