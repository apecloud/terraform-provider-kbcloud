# MSSQL Cluster Mode Configuration Guide

## Overview

MSSQL supports **Cluster mode** using Always On availability groups for high availability. This guide explains the configuration and deployment options.

---

## Supported Mode: Cluster Mode

### Cluster Mode (Always On Availability Groups)

MSSQL uses Windows Server Failover Clustering (WSFC) with Always On availability groups to provide high availability.

```hcl
mode = "cluster"
replicas = 3
class_code = "mssql.cluster.mssql.2c4g.general"
product_edition = "Enterprise"  # or "Developer"
```

**Components:**
- mssql: SQL Server instances with Always On enabled

**Features:**
- Automatic failover
- Synchronous/asynchronous replication
- Read-only secondary replicas
- Transparent client redirection

**Best for:** Production environments requiring high availability

---

## Configuration Examples

### Example 1: Development Cluster (Developer Edition)

**File:** `terraform.tfvars`

```hcl
cluster_name     = "mssql-dev"
mode             = "cluster"
replicas         = 2
storage_size_gb  = 20
class_code       = "mssql.cluster.mssql.2c4g.general"
product_edition  = "Developer"
termination_policy = "Delete"
```

**Deploy:**
```bash
./run.sh -t 1
```

---

### Example 2: Production Cluster (Enterprise Edition)

**File:** `terraform.tfvars`

```hcl
cluster_name     = "mssql-prod"
mode             = "cluster"
replicas         = 3
storage_size_gb  = 100
class_code       = "mssql.cluster.mssql.4c8g.general"
product_edition  = "Enterprise"
termination_policy = "DoNotTerminate"
collation        = "Chinese_PRC_CI_AS"
default_db_name  = "mydb"
```

**Deploy:**
```bash
./run.sh -t 1 \
    -cn "mssql-prod" \
    -r 3 \
    -s 100
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

### Cluster Mode (Always On)
- ✅ Automatic failover with Always On availability groups
- ✅ Synchronous commit for zero data loss
- ✅ Read-only routing to secondary replicas
- ✅ Transparent client redirection
- ❌ Requires Enterprise Edition for full features
- ❌ Minimum 3 replicas recommended for quorum

**Best for:** Production environments requiring high availability and disaster recovery

**Key Parameters:**
- `product_edition`: "Enterprise" or "Developer"
- `collation`: Database collation (e.g., "Chinese_PRC_CI_AS")
- `replicas`: Typically 3 for production (odd number for quorum)

---

## Scaling Operations

### VScale (Vertical Scaling)

Scale compute/storage for all nodes:

```bash
./run.sh -t 4 \
    -cc "mssql.cluster.mssql.4c8g.general" \
    -s 100
```

**Effect:** All SQL Server instances are scaled to new specifications

---

### HScale (Horizontal Scaling)

Add more replicas for better read performance:

```bash
./run.sh -t 5 \
    -r 5
```

**Effect:** Increases replica count for better read scaling and fault tolerance

**Note:** MSSQL Always On supports up to 8 secondary replicas

---

## Backup Configuration

MSSQL supports multiple backup methods:

### Full Backup
```hcl
auto_backup     = true
auto_backup_method = "full"
cron_expression = "0 2 * * *"
retention_period = "7d"
```

### Incremental Backup
```hcl
auto_backup                 = true
incremental_backup_enabled  = true
incremental_cron_expression = "0 */6 * * *"
```

### Transaction Log Backup (Continuous)
```hcl
pitr_enabled = true
continuous_backup_method = "transaction-log"
```

**Best Practice:** Combine full + incremental + transaction log for comprehensive backup strategy

---

## Monitoring Different Modes

### Check Cluster Status

```bash
# All modes
kubectl get clusters -n kubeblocks-cloud-ns

# Check component status
kubectl get pods -l app.kubernetes.io/instance=<cluster-name> -n kubeblocks-cloud-ns
```

### Check Always On Status

```bash
# Check primary/secondary roles
kubectl exec -it <mssql-pod> -n <namespace> -- sqlcmd -Q "SELECT role_desc FROM sys.dm_hadr_availability_replica_states"

# Check availability group health
kubectl exec -it <mssql-pod> -n <namespace> -- sqlcmd -Q "SELECT * FROM sys.dm_hadr_availability_group_states"
```

---

## Troubleshooting

### Issue: Cluster fails to initialize

**Check:**
1. Verify sufficient resources for all replicas
2. Ensure product edition is compatible (Enterprise/Developer)
3. Check pod logs for errors

```bash
kubectl describe cluster <cluster-name> -n kubeblocks-cloud-ns
kubectl logs -l app.kubernetes.io/component=mssql -n <namespace>
```

---

### Issue: Always On availability group not syncing

**Check:**
1. Verify network connectivity between replicas
2. Check if quorum is maintained (majority of replicas online)
3. Review SQL Server error logs

```bash
kubectl exec -it <mssql-pod> -n <namespace> -- sqlcmd -Q "SELECT * FROM sys.dm_hadr_database_replica_states"
```

---

### Issue: Insufficient resources

**Solution:**
Use smaller instance types or reduce replicas:

```hcl
replicas = 2  # Reduce from 3 to 2
class_code = "mssql.cluster.mssql.2c4g.general"  # Smaller instances
```

---

## Best Practices

### 1. Choose the Right Edition

- **Development/Testing:** Developer Edition (free, no production use)
- **Production:** Enterprise Edition (full features, licensing required)

### 2. Resource Planning

**Cluster Mode:**
- Memory: At least 4GB per instance (more for production)
- CPU: Based on query complexity and concurrency
- Storage: Database size + growth projection + tempdb space
- Replicas: Minimum 3 for production (odd number for quorum)

### 3. Backup Strategy

- Enable auto backup for all production clusters
- Use combination of full + incremental + transaction log backups
- Test restore procedures regularly
- Monitor backup success/failure
- Configure appropriate retention period (7-30 days typical)

### 4. Monitoring

- Set up alerts for CPU/memory usage (>80%)
- Monitor Always On synchronization state
- Track database size growth
- Watch for connection pool exhaustion
- Monitor transaction log size

---

## Additional Resources

- [Microsoft SQL Server Documentation](https://docs.microsoft.com/sql)
- [KubeBlocks MSSQL Guide](https://kubeblocks.io/docs)
- [RUN_SCRIPT_GUIDE.md](RUN_SCRIPT_GUIDE.md)
- [ops-examples/README.md](ops-examples/README.md)
