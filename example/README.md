# KBCloud Terraform Provider Examples

This directory contains example Terraform configurations for deploying various types of database and message queue clusters on KubeBlocks Enterprise. 

The configurations illustrate how to map KubeBlocks concepts (such as Components, Volumes, Parameter Templates, and Backup Policies) to the `kbcloud_cluster` Terraform resource.

## Supported Engines and Modes

Currently, the following examples are provided:

*   **MySQL** (`mysql`): Replication mode
*   **PostgreSQL** (`postgresql`): Replication mode
*   **Redis** (`redis`): Standalone, Replication, Sentinel, and Cluster modes
*   **MongoDB** (`mongodb`): Standalone, Replicaset, and Sharding modes
*   **Kafka** (`kafka`): Combined, Separated, and withZookeeper modes
*   **SQL Server** (`mssql`): Cluster mode

## KubeBlocks (KB) Cluster Operations via Terraform

The `kbcloud_cluster` resource translates standard Terraform lifecycle operations into KubeBlocks OpsRequest actions.

### 1. Provisioning a Cluster (`terraform apply`)

Creating a new cluster with `terraform apply` triggers the underlying `ClusterCreate` API. 
*   **Engine & Version**: Defined by the `engine` and `version` fields.
*   **Topology**: Defined by the `mode` (e.g., `standalone`, `replication`, `sharding`) and the `components` list.
*   **Storage**: Handled within each component's `volumes` block, supporting IOPS limits and storage classes.

### 2. Vertical Scaling (VScale)

To scale compute resources (CPU/Memory) or modify storage capacities, update the component specifications in your `.tf` file:
*   **Compute**: Change the `class_code` (e.g., from `...1c2g...` to `...2c4g...`).
*   **Storage**: Increase the `storage` value within a volume block (Note: decreasing storage is generally not supported by underlying cloud providers).

Running `terraform apply` will automatically issue the appropriate **Vertical Scale** or **Volume Expand** `OpsRequest` to the KubeBlocks API.

### 3. Horizontal Scaling (HScale)

To change the number of replicas or shards:
*   **Replicas**: Modify the `replicas` attribute inside the specific `component` block.
*   **Shards**: For sharded architectures (like Redis Cluster or MongoDB Sharding), modify the `comp_num` attribute.

Running `terraform apply` will issue a **Horizontal Scale** `OpsRequest`.

### 4. Parameter Reconfiguration

To apply a new parameter template to a component:
*   Update the `param_tpl_id` or `param_tpl_name` within the `param_tpls` block. 
*   Applying this change will trigger a **Reconfigure** `OpsRequest`.

### 5. Termination / Deletion (`terraform destroy`)

Executing `terraform destroy` will delete the cluster. 
*   Ensure that the `termination_policy` is set to `"Delete"` if you want the underlying resources to be completely removed. 
*   If `termination_policy` is `"DoNotTerminate"`, the provider will refuse to delete the cluster as a safety mechanism.

## Getting Started

### Quick Start with Automation Scripts (Recommended)

Each engine directory now includes an automated `run.sh` script for easy testing:

1. Navigate to the engine directory: `cd mysql`
2. View help: `./run.sh --help`
3. Create a cluster: `./run.sh -t 1 -cn "my-cluster" -r 3 -s 50`
4. Perform operations: `./run.sh -t 4 -cc "<class-code>"` (VScale)
5. Destroy cluster: `./run.sh -t 2`

See [RUN_SCRIPT_GUIDE.md](mysql/RUN_SCRIPT_GUIDE.md) for detailed usage.

### Manual Configuration

1. Navigate to the directory of the engine you want to provision (e.g., `cd mysql`).
2. Copy the template: `cp terraform.tfvars.example terraform.tfvars`
3. Edit `terraform.tfvars` and fill in your credentials and configuration.
4. Run `terraform init` to download the provider.
5. Run `terraform plan -var-file=terraform.tfvars` to preview the changes.
6. Run `terraform apply -var-file=terraform.tfvars` to provision the cluster.

## Advanced Operations Examples

Each engine directory now includes comprehensive examples using the new parameterized structure:

### Unified Structure (All Engines)

All engines follow the same pattern after refactoring:

- **main.tf**: Single parameterized cluster definition
- **variables.tf**: All configurable parameters
- **terraform.tfvars.example**: Configuration template
- **run.sh**: Automated test script with CLI parameters
- **ops-examples/**: Operation example files (.tfvars)
  - `vscale-up-compute.tfvars`: Vertical scaling
  - `hscale-out.tfvars`: Horizontal scaling (except MSSQL)
  - `reconfigure-params.tfvars`: Parameter changes
  - `backup-modify.tfvars`: Backup configuration
  - `termination-protect.tfvars`: Termination policy

### Using run.sh Script

```bash
# Create cluster
./run.sh -t 1 -cn "my-cluster" -r 3 -s 50

# Vertical scaling
./run.sh -t 4 -cc "mysql.replication.mysql.2c4g.general"

# Horizontal scaling
./run.sh -t 5 -r 5

# Modify backup
./run.sh -t 7 -ab true -bm "xtrabackup"

# Destroy cluster
./run.sh -t 2
```

### Using terraform.tfvars Directly

```bash
# Copy and edit template
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars

# Apply configuration
terraform apply -var-file=terraform.tfvars

# Apply operation overlay
terraform apply \
  -var-file=terraform.tfvars \
  -var-file=ops-examples/vscale-up-compute.tfvars
```

### Engine-Specific Details

#### MySQL (`mysql/`)
- Replication mode
- See [MySQL README](mysql/README.md) and [RUN_SCRIPT_GUIDE.md](mysql/RUN_SCRIPT_GUIDE.md)

#### PostgreSQL (`postgresql/`)
- Replication mode with WAL-G backup
- I/O configuration support
- See [PostgreSQL README](postgresql/README.md)

#### Redis (`redis/`)
- Multiple topology modes (Standalone, Replication, Sentinel, Cluster)
- See [Redis README](redis/README.md) and [MULTI_MODE_GUIDE.md](redis/MULTI_MODE_GUIDE.md)

#### MongoDB (`mongodb/`)
- Multiple topology modes (Standalone, Replicaset, Sharding)
- Multi-component sharding architecture
- See [MongoDB README](mongodb/README.md) and [MULTI_MODE_GUIDE.md](mongodb/MULTI_MODE_GUIDE.md)

#### Kafka (`kafka/`)
- Multiple deployment modes (Combined, Separated, withZookeeper)
- SASL authentication support
- See [Kafka README](kafka/README.md) and [MULTI_MODE_GUIDE.md](kafka/MULTI_MODE_GUIDE.md)

#### SQL Server (`mssql/`)
- Always On availability group configuration
- Enterprise edition features
- Note: No HScale support
- See [MSSQL README](mssql/README.md)

## Learning Path

### For Beginners
1. Read the [INDEX.md](INDEX.md) for overview
2. Choose your database engine
3. Use `./run.sh --help` to see available options
4. Deploy your first cluster: `./run.sh -t 1`
5. Review [RUN_SCRIPT_GUIDE.md](mysql/RUN_SCRIPT_GUIDE.md) for script usage

### For Intermediate Users
1. Study the engine-specific README files
2. Learn about different topology modes (Redis/MongoDB/Kafka)
3. Practice operations using run.sh or tfvars overlays
4. Understand parameterized configuration

### For Advanced Users
1. Review ops-examples/*.tfvars files
2. Understand how variables map to OpsRequests
3. Implement production-grade configurations
4. Master backup and disaster recovery strategies
5. Create custom tfvars for complex scenarios
