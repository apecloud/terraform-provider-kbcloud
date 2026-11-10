package resource

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	mytypes "github.com/apecloud/terraform-provider-kbcloud/internal/types"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

func TestBackupPolicySnapshotQueryBothAPIs(t *testing.T) {
	for _, adminClient := range []bool{true, false} {
		t.Run(map[bool]string{true: "admin", false: "public"}[adminClient], func(t *testing.T) {
			calls := 0
			server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				calls++
				if r.URL.Query().Get("useVolumeSnapshot") != "true" {
					t.Error("snapshot selection was not forwarded")
				}
				var body map[string]interface{}
				if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
					t.Fatal(err)
				}
				if body["autoBackup"] != true || body["cronExpression"] != "0 3 * * *" || body["retentionPeriod"] != "2d" {
					t.Errorf("policy %#v", body)
				}
				w.Header().Set("Content-Type", "application/json")
				json.NewEncoder(w).Encode(body)
			}))
			defer server.Close()
			ctx := context.Background()
			policy := mytypes.BackupResourceModel{AutoBackup: types.BoolValue(true), CronExpression: types.StringValue("0 3 * * *"), RetentionPeriod: types.StringValue("2d"), SnapshotVolumes: types.BoolValue(true)}
			value, diags := types.ObjectValueFrom(ctx, policy.AttributeTypes(), policy)
			if diags.HasError() {
				t.Fatal(diags)
			}
			data := mytypes.ClustersResourceModel{OrgName: types.StringValue("org"), Name: types.StringValue("source"), Backup: value}
			r := ClusterResource{client: backupTestClient(t, server.URL, adminClient)}
			if diags := r.doUpdateBackupPolicy(ctx, &data, &mytypes.ClustersResourceModel{}); diags.HasError() {
				t.Fatal(diags)
			}
			if diags := r.doUpdateBackupPolicy(ctx, &data, &data); diags.HasError() {
				t.Fatal(diags)
			}
			if calls != 1 {
				t.Fatalf("no-op sent %d policy updates", calls)
			}
		})
	}
}
