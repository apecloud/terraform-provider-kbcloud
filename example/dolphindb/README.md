# DolphinDB lifecycle (ApeCloud release-2.3)

This example manages a DolphinDB cluster with the generic `kbcloud_cluster` resource.

| Mode | Components |
| --- | --- |
| `standalone` | `standalone` |
| `integrated` | `controller`, `datanode` |
| `separated` | `controller`, `datanode`, `computenode` |

Each component has its own `data` and `log` volumes. Use `replicas` for node counts; DolphinDB does not use `comp_num`.

## Create

Copy the desired `*.tfvars.example` to `terraform.tfvars`, then set the organization, environment, cluster name and storage class. Set the API URL and credentials through environment variables:

```sh
export TF_VAR_api_url="https://your-apiserver"
# Set TF_VAR_admin_api_key and TF_VAR_admin_api_secret from your secret manager.
terraform init
terraform plan
terraform apply
```

The API endpoint is the control plane. `environment_name` selects the data plane where the database runs. For example, kb10 is a data-plane environment, not an API endpoint.

`class_codes` selects an existing class for each component. The example defaults to `dolphindb.<mode>.<component>.1c2g.general`; check the classes available in your environment (`GET /admin/v1/classes?engineName=dolphindb`). CPU and memory are read back from the selected class. Direct CPU/memory values do not replace class selection in release-2.3.

The default engine version is `2.0.19`. Choose a service version installed in the target environment. No custom license is supplied; the image's bundled license must permit the selected resources and node count. The v2.00.19 image tested on kb10 allowed 3 total nodes: the initial separated topology fit, while adding a second computenode was rejected because it required 4 nodes.

## Update

Edit `terraform.tfvars`, review `terraform plan`, then run `terraform apply`.

Scale the datanode in integrated mode:

```hcl
replicas = { datanode = 2 }
```

Change the standalone class and expand both volumes:

```hcl
class_codes  = { standalone = "dolphindb.standalone.standalone.2c4g.general" }
data_storage = { standalone = 11 }
log_storage  = { standalone = 2 }
```

Volumes can grow; shrinking is unsupported. The storage class must support expansion. Horizontal scaling is supported for datanode and computenode, subject to the engine's topology and license constraints.

Set independent parameters in separated mode:

```hcl
parameters = {
  datanode    = { workerNum = "3" }
  computenode = { workerNum = "4" }
}
```

Each component uses `dolphindb-config` / `dolphindb.cfg`. Only changed parameter keys are submitted, and refresh reads the current values of managed keys. To reset a parameter, explicitly configure its desired default; deleting a key cannot reset the database value and is rejected.

Scaling, volume expansion and parameter updates wait for the returned operation task (up to 30 minutes). Task failures are reported to Terraform. Parameter changes that require a restart are handled by the backend operation.

Name, organization, environment, project, topology, engine version, network mode, extra settings, license and parameter templates are creation settings in this provider's DolphinDB support. In-place changes are rejected. Engine upgrades, topology conversion, start/stop/restart actions, rebalance and additional compute-group resources are outside this example's lifecycle scope.

After operations finish, a second `terraform plan -detailed-exitcode` should return 0. Cluster creation returns after the API creates the resource; check the cluster reaches Running before using database connections.

## Delete

```sh
terraform plan -destroy
terraform destroy
```

This example uses `termination_policy = "Delete"`. Check the provider API and data-plane resources to confirm cleanup. Kubernetes may finish deletion after the API returns; allow cleanup to finish before immediately recreating the same cluster name.
