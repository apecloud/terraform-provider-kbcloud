# Kafka Multi-Mode Configuration Guide

## Overview

Kafka supports multiple deployment modes. The refactored configuration uses a **single flexible cluster definition** that can be configured for different modes through variables.

---

## Supported Modes

### 1. Combined Mode (Default)
Nodes simultaneously act as both Broker and Controller roles. Recommended for most use cases.

```hcl
mode = "combined"
replicas = 3
class_code = "kafka.combined.kafka-combine.1c1g.general"
```

**Components:**
- kafka-combine: Handles both message brokering and cluster coordination

**Best for:** General purpose, simpler architecture, Kafka 3.3+

---

### 2. Separated Mode
Nodes play only one role: either Broker or Controller. Provides better resource isolation.

```hcl
mode = "separated"
broker_replicas = 3
controller_replicas = 3
broker_class_code = "kafka.separated.kafka-broker.1c1g.general"
controller_class_code = "kafka.separated.kafka-controller.1c1g.general"
```

**Components:**
- kafka-broker: Handles message brokering
- kafka-controller: Handles cluster coordination

**Best for:** High-throughput scenarios, better resource isolation, Kafka 3.3+

---

### 3. With ZooKeeper Mode (Legacy)
Uses ZooKeeper for managing cluster metadata and coordinating tasks. Compatible with KubeBlocks 0.9.

```hcl
mode = "withZookeeper"
broker_replicas = 3
zookeeper_replicas = 3
broker_class_code = "kafka.withZookeeper.kafka-broker.1c1g.general"
```

**Components:**
- kafka-broker: Message brokering
- kafka-zookeeper: Cluster metadata management

**Versions:** 2.8.2, 2.8.1

**Best for:** Legacy systems, compatibility with older Kafka versions

---

### 4. With ZooKeeper-10 Mode (KubeBlocks 1.0)
Similar to withZookeeper mode but compatible with KubeBlocks 1.0. Uses external ZooKeeper service reference.

```hcl
mode = "withZookeeper-10"
broker_replicas = 3
zookeeper_cluster_ref = "my-zookeeper-cluster"
```

**Components:**
- kafka-broker: Message brokering
- kb-zookeeper: References external ZooKeeper cluster

**Versions:** 2.8.2, 2.8.1

**Best for:** KubeBlocks 1.0 environments, shared ZooKeeper clusters

---

## Configuration Examples

### Example 1: Simple Combined Mode (Development)

**File:** `terraform.tfvars`

```hcl
cluster_name     = "kafka-dev"
mode             = "combined"
replicas         = 3
storage_size_gb  = 20
class_code       = "kafka.combined.kafka-combine.1c1g.general"
```

**Deploy:**
```bash
./run.sh -t 1
```

---

### Example 2: Production Separated Mode

**File:** `terraform.tfvars`

```hcl
cluster_name     = "kafka-prod"
mode             = "separated"
broker_replicas         = 3
controller_replicas     = 3
broker_storage_gb       = 100
controller_storage_gb   = 20
broker_class_code       = "kafka.separated.kafka-broker.4c8g.performance"
controller_class_code   = "kafka.separated.kafka-controller.2c4g.general"
termination_policy      = "DoNotTerminate"
```

**Deploy:**
```bash
./run.sh -t 1 \
    -cn "kafka-prod" \
    -m "separated"
```

Then manually edit `terraform.tfvars` to add separated mode parameters.

---

### Example 3: With ZooKeeper Mode (Legacy)

**File:** `terraform.tfvars`

```hcl
cluster_name     = "kafka-legacy"
mode             = "withZookeeper"
broker_replicas  = 3
zookeeper_replicas = 3
version          = "2.8.2"
```

**Deploy:**
```bash
./run.sh -t 1 \
    -cn "kafka-legacy" \
    -m "withZookeeper" \
    -v "2.8.2"
```

---

## Switching Between Modes

### Important Notes

⚠️ **You cannot change the mode of an existing cluster.** To switch modes:

1. Destroy the current cluster:
   ```bash
   ./run.sh -t 2
   ```

2. Update `terraform.tfvars` with new mode configuration

3. Create new cluster:
   ```bash
   ./run.sh -t 1
   ```

---

## Mode-Specific Considerations

### Combined Mode
- ✅ Simpler architecture
- ✅ Fewer components to manage
- ✅ Lower resource overhead
- ❌ Less resource isolation
- ❌ Single point of failure for coordination

**Best for:** Most use cases, development, small to medium deployments

---

### Separated Mode
- ✅ Better resource isolation
- ✅ Independent scaling of brokers and controllers
- ✅ Higher throughput potential
- ❌ More complex architecture
- ❌ More components to manage

**Best for:** High-throughput production, large-scale deployments

**Key Parameters:**
- `broker_replicas`: Number of broker nodes
- `controller_replicas`: Number of controller nodes (typically 3 or 5)
- Separate class codes for brokers and controllers

---

### With ZooKeeper Mode
- ✅ Compatible with legacy Kafka versions
- ✅ Familiar architecture for existing users
- ❌ Additional ZooKeeper maintenance
- ❌ Not recommended for new deployments (Kafka 3.3+ has built-in coordination)

**Best for:** Legacy systems, migration scenarios

**Key Parameters:**
- `version`: Must be 2.8.x
- `zookeeper_replicas`: Typically 3 or 5 (odd number)

---

## Scaling Operations

### VScale (All Modes)

Scale compute/storage for all nodes:

```bash
./run.sh -t 4 \
    -cc "kafka.combined.kafka-combine.2c4g.general" \
    -s 50
```

**Effect:** All nodes are scaled to new specifications

---

### HScale (Combined/Separated Modes)

Add more replicas:

```bash
./run.sh -t 5 \
    -r 5
```

**Effect:** Increases replica count for better throughput and fault tolerance

---

### HScale (Separated Mode - Advanced)

For separated mode, you can scale brokers and controllers independently by editing `terraform.tfvars`:

```hcl
# Increase brokers only
broker_replicas = 5
# Keep controllers at 3
controller_replicas = 3
```

Then apply:
```bash
terraform apply -var-file=terraform.tfvars
```

---

## SASL Authentication

All modes support SASL authentication:

### Combined/Separated Mode

```hcl
extra = {
  sasl = {
    enable = true
  }
}
```

**Client Configuration:**
```properties
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='xx' password='xx'
```

### With ZooKeeper Mode

```hcl
extra = {
  saslScramEnable = true
}
```

Uses SCRAM-SHA-512 authentication mechanism.

---

## Backup Configuration

All modes support topic backups:

```hcl
auto_backup_enabled = true
auto_backup_method = "topics"
backup_schedule = "0 2 * * *"
retention_period = "7d"
```

**Note:** Backups capture topic configurations and metadata, not message data.

---

## Monitoring Different Modes

### Check Cluster Status

```bash
# All modes
kubectl get clusters -n kubeblocks-cloud-ns

# Check component status
kubectl get pods -l app.kubernetes.io/instance=<cluster-name> -n kubeblocks-cloud-ns
```

### Mode-Specific Checks

**Combined Mode:**
```bash
kubectl get pods -l app.kubernetes.io/component=kafka-combine -n <namespace>
```

**Separated Mode:**
```bash
# Check brokers
kubectl get pods -l app.kubernetes.io/component=kafka-broker -n <namespace>

# Check controllers
kubectl get pods -l app.kubernetes.io/component=kafka-controller -n <namespace>
```

**With ZooKeeper Mode:**
```bash
# Check brokers
kubectl get pods -l app.kubernetes.io/component=kafka-broker -n <namespace>

# Check ZooKeeper
kubectl get pods -l app.kubernetes.io/component=kafka-zookeeper -n <namespace>
```

---

## Troubleshooting

### Issue: Combined mode fails to initialize

**Check:**
1. Verify sufficient resources for combined role
2. Check if version supports combined mode (3.3+)
3. Review pod logs

```bash
kubectl describe cluster <cluster-name> -n kubeblocks-cloud-ns
kubectl logs -l app.kubernetes.io/component=kafka-combine -n <namespace>
```

---

### Issue: Separated mode has connectivity problems

**Check:**
1. Verify both broker and controller pods are running
2. Ensure controller quorum (at least 2 of 3 controllers)
3. Check network policies

```bash
kubectl get pods -l app.kubernetes.io/component=kafka-controller -n <namespace>
kubectl logs -l app.kubernetes.io/component=kafka-controller -n <namespace>
```

---

### Issue: ZooKeeper mode connection failures

**Check:**
1. Verify ZooKeeper ensemble is healthy
2. Ensure odd number of ZooKeeper nodes (3, 5, 7)
3. Check ZooKeeper logs

```bash
kubectl logs -l app.kubernetes.io/component=kafka-zookeeper -n <namespace>
```

---

## Best Practices

### 1. Choose the Right Mode

- **Development/Testing:** Combined mode (simpler)
- **Production (medium):** Combined or Separated mode
- **Production (large/high-throughput):** Separated mode
- **Legacy systems:** With ZooKeeper mode (migration path)

### 2. Resource Planning

**Combined Mode:**
- CPU: 2-4 cores per node minimum
- Memory: 4-8GB per node minimum
- Storage: Based on retention policy and throughput

**Separated Mode:**
- Brokers: Higher CPU/memory for message handling
- Controllers: Lower resources (coordination only)
- Plan for independent scaling

**With ZooKeeper Mode:**
- Brokers: Same as combined mode
- ZooKeeper: Minimal resources (1-2 CPU, 2-4GB RAM)
- Odd number of ZooKeeper nodes (3, 5, 7)

### 3. Version Selection

- **New deployments:** Use Kafka 3.9.0 or later with combined/separated mode
- **Legacy compatibility:** Use 2.8.x with ZooKeeper mode only if required
- **Avoid mixing:** Don't mix old and new versions in same environment

### 4. Monitoring

- Set up alerts for broker health
- Monitor consumer lag
- Track throughput metrics
- Watch for under-replicated partitions
- Monitor ZooKeeper health (if using ZooKeeper mode)

---

## Migration Paths

### From With ZooKeeper to Combined/Separated

1. Create new cluster with combined/separated mode
2. Migrate topics and configurations
3. Update client connections
4. Test thoroughly
5. Decommission old cluster

**Note:** Message data migration requires additional tools (MirrorMaker, etc.)

---

## Additional Resources

- [Apache Kafka Documentation](https://kafka.apache.org/documentation)
- [KubeBlocks Kafka Guide](https://kubeblocks.io/docs)
- [RUN_SCRIPT_GUIDE.md](RUN_SCRIPT_GUIDE.md)
- [ops-examples/README.md](ops-examples/README.md)
