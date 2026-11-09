package resource

import (
	"context"
	"fmt"
	"time"

	"github.com/apecloud/kb-cloud-client-go/api/kbcloud"
	"github.com/apecloud/kb-cloud-client-go/api/kbcloud/admin"
	"github.com/apecloud/terraform-provider-kbcloud/internal/client"
)

func waitForRunningCluster(ctx context.Context, c *client.Client, org, name string) error {
	return waitUntil(ctx, 5*time.Second, func() (bool, error) {
		var status string
		if c.IsAdminClient() {
			cluster, response, err := admin.NewClusterApi(c.AdminClient()).GetCluster(ctx, org, name)
			if err := apiError(response, err); err != nil {
				return false, err
			}
			status = cluster.GetStatus()
		} else {
			cluster, response, err := kbcloud.NewClusterApi(c.Client()).GetCluster(ctx, org, name)
			if err := apiError(response, err); err != nil {
				return false, err
			}
			status = cluster.GetStatus()
		}
		switch status {
		case "Running":
			return true, nil
		case "Failed", "Abnormal", "Stopped", "Deleting":
			return false, fmt.Errorf("cluster %s is %s", name, status)
		default:
			return false, nil
		}
	})
}
