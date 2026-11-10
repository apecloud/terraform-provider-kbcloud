# DolphinDB backup and restore

Use this example with existing source and target clusters managed by the parent
[DolphinDB example](../README.md). The provider waits for each cluster to be
Running and each backup/restore to reach Completed (30-minute timeout).

Configure the source cluster's `backup` object before running backups:

```hcl
backup = {
  auto_backup        = true
  auto_backup_method = "native"
  backup_repo        = "<ready backup repository>"
  cron_expression    = "0 3 * * *"
  retention_period   = "7d"
  retention_policy   = "Retain"
}
```

Set `auto_backup = false` to disable the schedule while keeping manual backup
available. Repository selection belongs to the cluster policy. release-2.3
DolphinDB supports `native` full backups and `native-selective` selections;
it does not offer incremental or continuous/PITR backup methods.

1. Set credentials through `TF_VAR_admin_api_key` and `TF_VAR_admin_api_secret`.
   Set `api_url`, `org_name`, `source_cluster_name` and `component` in your own
   `.tfvars` file. Use `standalone` for standalone mode, `datanode` for integrated
   or separated mode. Never use the controller or computenode as a backup target.
2. Run `terraform init`, then `terraform apply -var-file=<your file>`. By default,
   this creates one full backup. Add `-var-file=selective.tfvars.example` after
   adapting its database/table/partition paths to create a selective backup.
   Selection nodes use the API's camelCase `selectedAll`, not `selected_all`.
3. Provision a separate compatible target cluster in the **same environment and
   Kubernetes namespace** as the backup. For full recovery use an empty cluster
   with matching DolphinDB version/topology; provision it with the parent example.
4. Review a plan with `restore_enabled = true` and `target_cluster_name` set.
   Apply it to restore the backup. Query the target database to verify your data.
   For selective recovery, `FAIL` rejects existing selected tables. `OVERWRITE`
   replaces selected backed-up partitions while preserving unselected partitions.
   The example sets `FAIL`; release-2.3 defaults to `OVERWRITE` if the parameter
   is omitted when using the resource directly.

`kbcloud_backup` and `kbcloud_restore` represent one operation each. Subsequent
applies with unchanged inputs do not take new backups or replay recovery. Use the
cluster schedule for recurring backups. All input changes require replacement.
Use a separate resource name to retain an older snapshot; consider Terraform
`lifecycle { prevent_destroy = true }` for backups you need to keep. Expired
backups disappear from state on refresh and are recreated if still configured.

**Destroying `kbcloud_backup` deletes its stored backup files.** Destroying
`kbcloud_restore` removes the operation object, and does **not** undo restored data.
Replacing a restore reruns recovery; review that plan before applying. If server
history was removed, refresh retains the restore state with a warning instead of
automatically replaying it. Deleting the target cluster is a separate operation.

The provider supports admin and organization API clients.
