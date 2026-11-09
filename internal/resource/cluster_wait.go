package resource

import (
	"context"
	"fmt"
	"time"

	"github.com/apecloud/kb-cloud-client-go/api/kbcloud"
	"github.com/apecloud/kb-cloud-client-go/api/kbcloud/admin"
	"github.com/hashicorp/terraform-plugin-framework/diag"
)

// waitForTask keeps dependent operations sequential and does not report an
// accepted operation as a successful change before the backend finishes it.
func (r *ClusterResource) waitForTask(ctx context.Context, orgName, taskID string) diag.Diagnostics {
	var diags diag.Diagnostics
	if taskID == "" {
		diags.AddError("Missing operation task", "The API did not return a task ID, so the operation result cannot be verified.")
		return diags
	}
	authCtx := r.client.Ctx()
	if r.client.IsAdminClient() {
		authCtx = r.client.AdminCtx()
	}
	apiCtx, cancel := context.WithTimeout(authCtx, 30*time.Minute)
	defer cancel()
	stop := context.AfterFunc(ctx, cancel)
	defer stop()
	err := pollTask(apiCtx, 5*time.Second, func() (string, string, error) {
		if r.client.IsAdminClient() {
			task, _, err := admin.NewTaskApi(r.client.AdminClient()).GetTask(apiCtx, taskID)
			return string(task.Status), task.GetMessage(), err
		}
		task, _, err := kbcloud.NewTaskApi(r.client.Client()).GetTask(apiCtx, orgName, taskID)
		return string(task.Status), task.GetMessage(), err
	})
	if err != nil {
		diags.AddError("Cluster operation did not complete", fmt.Sprintf("Task %s: %s", taskID, err))
	}
	return diags
}

func pollTask(ctx context.Context, interval time.Duration, get func() (status, message string, err error)) error {
	for {
		if err := ctx.Err(); err != nil {
			return err
		}
		status, message, err := get()
		if err != nil {
			return err
		}
		switch status {
		case "Succeed", "Finished":
			return nil
		case "Failed", "Stopped", "Cancelled", "Deleted", "RebuildCanceled":
			return fmt.Errorf("%s: %s", status, message)
		case "Pending", "Running", "Cancelling":
		default:
			return fmt.Errorf("unrecognized task status %q", status)
		}
		timer := time.NewTimer(interval)
		select {
		case <-ctx.Done():
			timer.Stop()
			return ctx.Err()
		case <-timer.C:
		}
	}
}
