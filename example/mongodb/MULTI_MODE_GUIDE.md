# MongoDB Multi-Mode Configuration Guide

## Overview

MongoDB supports multiple deployment modes. The refactored configuration uses a **single flexible cluster definition** that can be configured for different modes through variables.

---

## Supported Modes

### 1. Standalone Mode
Single-node MongoDB instance (for development/testing).

```hcl
mode = "standalone"
replicas = 1
```

### 2. Replication Mode (Default)
Primary-replica architecture for high availability.

```hcl
mode = "replication"
replicas = 2  # 1 primary + 1 replica
class_code = "mongodb.replication.mongodb.2c2g.general"
```

### 3. Cluster Mode
Sharded cluster for horizontal scaling and large datasets.

```hcl
mode = "cluster"
comp_num = 3  # Number of shards
replicas = 2  # Replicas per shard
network_mode = "HeadlessService"
class_code = "mongodb.cluster.mongodb-cluster.2c1g.general"
component_name = "mongodb-cluster"
param_tpl_name = "mongodb-cluster-default-parameter-template"
```

**Total nodes:** `comp_num * replicas = 3 * 2 = 6 nodes`

### 4. Sentinel Mode
Sentinel-based high availability with automatic failover.

```hcl
mode = "sentinel"
replicas = 2  # MongoDB data nodes
network_mode = "HostNetwork"
extra_sentinel = "{}"

# Sentinel component configuration
sentinel_component_name = "mongodb-sentinel"
sentinel_replicas = 3
sentinel_class_code = "mongodb.sentinel.mongodb-sentinel.1c2g.general"
```

**Total components:** 
- 1 MongoDB component (2 replicas)
- 1 Sentinel component (3 replicas)

---

## Configuration Examples

### Example 1: Simple Replication (Production Ready)

**File:** `terraform.tfvars`

```hcl
cluster_name     = "mongodb-prod"
mode             = "replication"
replicas         = 3
storage_size_gb  = 50
class_code       = "mongodb.replication.mongodb.4c4g.general"
termination_policy = "DoNotTerminate"
```

**Deploy:**
```bash
./run.sh -t 1
```

---

### Example 2: Cluster Mode (Large Dataset)

**File:** `terraform-cluster.tfvars`

```hcl
cluster_name     = "mongodb-cluster-prod"
mode             = "cluster"
comp_num         = 6        # 6 shards
replicas         = 2        # 2 replicas per shard
network_mode     = "HeadlessService"
storage_size_gb  = 100
class_code       = "mongodb.cluster.mongodb-cluster.4c2g.general"
component_name   = "mongodb-cluster"
param_tpl_name   = "mongodb-cluster-default-parameter-template"
```

**Deploy:**
```bash
./run.sh -t 1 \
    -cn "mongodb-cluster-prod" \
    -m "cluster" \
    -r 2
```

Then manually edit `terraform.tfvars` to add:
```hcl
comp_num = 6
network_mode = "HeadlessService"
component_name = "mongodb-cluster"
```

---

### Example 3: Sentinel Mode (High Availability)

**File:** `terraform-sentinel.tfvars`

```hcl
cluster_name     = "mongodb-sentinel-prod"
mode             = "sentinel"
replicas         = 2
network_mode     = "HostNetwork"
extra_sentinel   = "{}"

# Primary MongoDB component
component_name   = "mongodb"
class_code       = "mongodb.sentinel.mongodb.2c1g.general"

# Sentinel component
sentinel_replicas = 3
sentinel_class_code = "mongodb.sentinel.mongodb-sentinel.1c2g.general"
```

**Deploy:**
```bash
./run.sh -t 1 \
    -cn "mongodb-sentinel-prod" \
    -m "sentinel" \
    -r 2
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

### Replication Mode
- ✅ Simple setup
- ✅ Automatic failover
- ✅ Read scaling with replicas
- ❌ Limited by single-node memory

**Best for:** Medium-sized datasets, simple HA requirements

---

### Cluster Mode
- ✅ Horizontal scaling (sharding)
- ✅ Very large datasets
- ✅ High throughput
- ❌ More complex management
- ❌ Requires `comp_num` configuration

**Best for:** Large datasets (>100GB), high throughput requirements

**Key Parameters:**
- `comp_num`: Number of shards (affects total capacity)
- `network_mode`: Must be "HeadlessService"
- `component_name`: Should be "mongodb-cluster"

---

### Sentinel Mode
- ✅ Automatic failover
- ✅ Client-side discovery
- ✅ Flexible topology
- ❌ Requires separate sentinel nodes
- ❌ More resource overhead

**Best for:** Complex HA requirements, existing MongoDB clients using Sentinel

**Key Parameters:**
- `network_mode`: Usually "HostNetwork"
- `extra_sentinel`: Sentinel configuration (JSON)
- `sentinel_replicas`: Typically 3 or 5 (odd number)

---

## Scaling Operations

### VScale (All Modes)

Scale compute/storage for all nodes:

```bash
./run.sh -t 4 \
    -cc "mongodb.replication.mongodb.4c4g.general" \
    -s 100
```

**Effect:** All nodes (primary, replicas, sentinels) are scaled

---

### HScale (Replication/Sentinel Modes)

Add more replicas:

```bash
./run.sh -t 5 \
    -r 5
```

**Effect:** Increases replica count for better read scaling

---

### HScale (Cluster Mode)

For cluster mode, you typically scale by adding shards:

```hcl
# In terraform.tfvars
comp_num = 9  # Increase from 6 to 9 shards
```

Then apply:
```bash
terraform apply -var-file=terraform.tfvars
```

**Note:** This triggers a resharding operation which may take time.

---

## Backup Configuration

All modes support backup with slight differences:

### Replication/Standalone
```hcl
auto_backup  = true
pitr_enabled = true
continuous_backup_method = "pbm-pitr"
```

### Cluster Mode
```hcl
auto_backup  = true
pitr_enabled = false  # PITR not supported in cluster mode
continuous_backup_method = "pbm-pitr"
```

### Sentinel Mode
```hcl
auto_backup  = true
pitr_enabled = false  # PITR usually disabled for sentinel
continuous_backup_method = "pbm-pitr"
```

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

**Replication:**
```bash
# Check replication status
kubectl exec -it <primary-pod> -n <namespace> -- mongodb-cli info replication
```

**Cluster:**
```bash
# Check cluster info
kubectl exec -it <pod> -n <namespace> -- mongodb-cli cluster info
kubectl exec -it <pod> -n <namespace> -- mongodb-cli cluster nodes
```

**Sentinel:**
```bash
# Check sentinel status
kubectl exec -it <sentinel-pod> -n <namespace> -- mongodb-cli -p 26379 info sentinel
```

---

## Troubleshooting

### Issue: Cluster mode fails to initialize

**Check:**
1. Verify `comp_num` is set correctly
2. Ensure `network_mode = "HeadlessService"`
3. Check if `component_name = "mongodb-cluster"`
4. Verify sufficient resources for all shards

```bash
kubectl describe cluster <cluster-name> -n kubeblocks-cloud-ns
```

---

### Issue: Sentinel mode has connectivity problems

**Check:**
1. Verify `network_mode = "HostNetwork"`
2. Ensure `extra_sentinel` is properly configured
3. Check sentinel pod logs

```bash
kubectl logs -l app.kubernetes.io/component=mongodb-sentinel -n kubeblocks-cloud-ns
```

---

### Issue: Insufficient resources for cluster mode

**Solution:**
Reduce `comp_num` or use smaller instance types:

```hcl
comp_num = 3  # Reduce from 6 to 3
class_code = "mongodb.cluster.mongodb-cluster.1c1g.general"  # Smaller instances
```

---

## Best Practices

### 1. Choose the Right Mode

- **Development:** Standalone or small replication
- **Production (medium):** Replication with 3+ replicas
- **Production (large):** Cluster mode with appropriate shards
- **Legacy compatibility:** Sentinel mode

### 2. Resource Planning

**Replication Mode:**
- Memory: Total dataset size + 20% overhead
- CPU: Based on QPS requirements
- Storage: Dataset size + growth projection

**Cluster Mode:**
- Per-shard memory: Total dataset / comp_num
- Total nodes: comp_num × replicas
- Plan for resharding overhead

**Sentinel Mode:**
- Data nodes: Same as replication
- Sentinel nodes: Minimal resources (1c2g typical)
- Odd number of sentinels (3, 5, 7)

### 3. Backup Strategy

- Enable auto backup for all production clusters
- Test restore procedures regularly
- Monitor backup success/failure
- Configure appropriate retention period

### 4. Monitoring

- Set up alerts for memory usage (>80%)
- Monitor replication lag
- Track hit rate (should be >90% for cache)
- Watch for connection pool exhaustion

---

## Migration Paths

### From Standalone to Replication

1. Create new replication cluster
2. Migrate data using MongoDB migration tools
3. Update application configuration
4. Decommission standalone cluster

### From Replication to Cluster

1. Create new cluster mode deployment
2. Use MongoDB Cluster migration tools
3. Test thoroughly
4. Switch traffic gradually

---

## Additional Resources

- [MongoDB Documentation](https://mongodb.io/documentation)
- [KubeBlocks MongoDB Guide](https://kubeblocks.io/docs)
- [RUN_SCRIPT_GUIDE.md](RUN_SCRIPT_GUIDE.md)
- [ops-examples/README.md](ops-examples/README.md)
