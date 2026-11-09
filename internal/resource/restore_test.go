package resource

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/tfsdk"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

func TestRestoreLifecycleBothAPIs(t *testing.T) {
	for _, adminClient := range []bool{true, false} {
		t.Run(map[bool]string{true: "admin", false: "public"}[adminClient], func(t *testing.T) {
			for _, failed := range []bool{false, true} {
				t.Run(map[bool]string{true: "failure_keeps_operation", false: "completed"}[failed], func(t *testing.T) {
					ctx := context.Background()
					missing := false
					deleted := false
					posts := 0
					prefix := "/api/v1"
					if adminClient {
						prefix = "/admin/v1"
					}
					item := `{"backupName":"snapshot","clusterName":"target","name":"restore-operation","status":{"phase":"Completed"}}`
					if failed {
						item = strings.Replace(item, "Completed", "Failed", 1)
					}
					server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
						w.Header().Set("Content-Type", "application/json")
						if !strings.HasPrefix(r.URL.Path, prefix+"/organizations/org/clusters/target") {
							t.Errorf("wrong target %s", r.URL.Path)
						}
						if strings.HasSuffix(r.URL.Path, "/clusters/target") {
							w.Write([]byte(`{"environmentName":"test","name":"target","engine":"dolphindb","status":"Running"}`))
							return
						}
						switch r.Method {
						case http.MethodPost:
							posts++
							var body map[string]interface{}
							if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
								t.Error(err)
							}
							if body["clusterName"] != "target" || body["backupName"] != "snapshot" || body["componentName"] != "standalone" || body["parameters"].(map[string]interface{})["conflict_policy"] != "FAIL" {
								t.Errorf("wrong body %#v", body)
							}
							if len(body["selectedObjects"].([]interface{})) != 1 {
								t.Error("missing selection")
							}
							w.Write([]byte(`{"backupName":"snapshot","clusterName":"target","name":"restore-operation","status":{"phase":""}}`))
						case http.MethodGet:
							if missing {
								w.Write([]byte(`{"items":[]}`))
							} else {
								w.Write([]byte(`{"items":[` + item + `]}`))
							}
						case http.MethodDelete:
							deleted = true
							if r.URL.Query().Get("restoreName") != "restore-operation" {
								t.Error("wrong delete name")
							}
							w.WriteHeader(http.StatusNotFound)
							w.Write([]byte(`{}`))
						default:
							t.Errorf("unexpected method %s", r.Method)
						}
					}))
					defer server.Close()
					r := &RestoreResource{client: backupTestClient(t, server.URL, adminClient)}
					var schemaResp resource.SchemaResponse
					r.Schema(ctx, resource.SchemaRequest{}, &schemaResp)
					parameters, _ := types.MapValueFrom(ctx, types.StringType, map[string]string{"conflict_policy": "FAIL"})
					data := restoreModel{ID: types.StringUnknown(), OrgName: types.StringValue("org"), ClusterName: types.StringValue("target"), BackupName: types.StringValue("snapshot"), Component: types.StringValue("standalone"), Parameters: parameters, SelectedObjectsJSON: types.StringValue(selectionExample), Status: types.StringUnknown()}
					plan := tfsdk.Plan{Schema: schemaResp.Schema}
					if d := plan.Set(ctx, &data); d.HasError() {
						t.Fatal(d)
					}
					created := resource.CreateResponse{State: tfsdk.State{Schema: schemaResp.Schema}}
					r.Create(ctx, resource.CreateRequest{Plan: plan}, &created)
					if created.Diagnostics.HasError() != failed {
						t.Fatalf("diagnostics: %v", created.Diagnostics)
					}
					if d := created.State.Get(ctx, &data); d.HasError() {
						t.Fatal(d)
					}
					if data.ID.ValueString() != "restore-operation" || data.SelectedObjectsJSON.ValueString() != selectionExample {
						t.Fatalf("state %#v", data)
					}
					missing = true
					read := resource.ReadResponse{State: created.State}
					r.Read(ctx, resource.ReadRequest{State: created.State}, &read)
					if read.Diagnostics.HasError() || len(read.Diagnostics) == 0 || read.State.Raw.IsNull() || posts != 1 {
						t.Fatal("missing history must retain operation without replay")
					}
					del := resource.DeleteResponse{State: created.State}
					r.Delete(ctx, resource.DeleteRequest{State: created.State}, &del)
					if del.Diagnostics.HasError() || !deleted {
						t.Fatal(del.Diagnostics)
					}
				})
			}
		})
	}
}
