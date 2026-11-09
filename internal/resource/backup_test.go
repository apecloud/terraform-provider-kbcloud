package resource

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/apecloud/terraform-provider-kbcloud/internal/client"
	mytypes "github.com/apecloud/terraform-provider-kbcloud/internal/types"
	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/tfsdk"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

const selectionExample = `[{"type":"database","name":"dfs://market","children":[{"type":"table","name":"trades","children":[{"type":"partition","name":"/2","selectedAll":true}]}]}]`
const backupResponse = `{"id":"42","autoBackup":false,"backupMethod":"native-selective","backupPolicyName":"policy","backupType":"Selective","creationTimestamp":"2026-11-09T00:00:00Z","name":"snapshot","orgName":"org","snapshotVolumes":false,"sourceCluster":"source","status":"Completed","totalSize":"1Ki","retentionPeriod":"1d","environmentName":"test","engine":"dolphindb"}`

func backupTestClient(t *testing.T, url string, admin bool) *client.Client {
	t.Helper()
	config := mytypes.ProviderSchema{APIUrl: types.StringValue(url)}
	if admin {
		config.AdminAPIKey = types.StringValue("test")
		config.AdminAPISecret = types.StringValue("test")
	} else {
		config.APIKey = types.StringValue("test")
		config.APISecret = types.StringValue("test")
	}
	c, err := client.New(config)
	if err != nil {
		t.Fatal(err)
	}
	return c
}

func TestBackupLifecycleBothAPIs(t *testing.T) {
	for _, adminClient := range []bool{true, false} {
		t.Run(map[bool]string{true: "admin", false: "public"}[adminClient], func(t *testing.T) {
			for _, failed := range []bool{false, true} {
				t.Run(map[bool]string{true: "failure_keeps_id", false: "completed"}[failed], func(t *testing.T) {
					ctx := context.Background()
					deleted := false
					readStatus := http.StatusOK
					posts := 0
					prefix := "/api/v1"
					if adminClient {
						prefix = "/admin/v1"
					}
					server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
						w.Header().Set("Content-Type", "application/json")
						if !strings.HasPrefix(r.URL.Path, prefix+"/organizations/org/") && r.URL.Path != prefix+"/backups" {
							t.Errorf("wrong scope %s", r.URL.Path)
						}
						if strings.HasSuffix(r.URL.Path, "/clusters/source") {
							w.Write([]byte(`{"environmentName":"test","name":"source","engine":"dolphindb","version":"2.0.19","status":"Running"}`))
							return
						}
						switch r.Method {
						case http.MethodPost:
							posts++
							var body map[string]interface{}
							if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
								t.Error(err)
							}
							if body["backupType"] != "Selective" || body["backupMethod"] != "native-selective" || body["component"] != "standalone" {
								t.Errorf("bad body %#v", body)
							}
							nodes := body["selectedObjects"].([]interface{})
							partition := nodes[0].(map[string]interface{})["children"].([]interface{})[0].(map[string]interface{})["children"].([]interface{})[0].(map[string]interface{})
							if partition["name"] != "/2" {
								t.Errorf("selection lost: %#v", body)
							}
							w.Write([]byte(strings.Replace(backupResponse, `"status":"Completed"`, `"status":"New"`, 1)))
						case http.MethodGet:
							if strings.HasSuffix(r.URL.Path, "/backups") {
								if r.URL.Query().Get("withDeletedBackups") != "false" || r.URL.Query().Get("clusterName") != "source" {
									t.Error("active backup list must be scoped")
								}
								if deleted {
									w.Write([]byte(`{"items":[]}`))
								} else {
									w.Write([]byte(`{"items":[` + backupResponse + `]}`))
								}
								return
							}
							if deleted {
								w.WriteHeader(404)
								w.Write([]byte(`{}`))
								return
							}
							if readStatus != 200 {
								w.WriteHeader(readStatus)
								w.Write([]byte(`{}`))
								return
							}
							body := backupResponse
							if failed {
								body = strings.Replace(body, `"status":"Completed"`, `"status":"Failed","failureReason":"disk full"`, 1)
							}
							w.Write([]byte(body))
						case http.MethodDelete:
							deleted = true
							w.WriteHeader(204)
						default:
							t.Errorf("unexpected method %s", r.Method)
						}
					}))
					defer server.Close()
					r := &BackupResource{client: backupTestClient(t, server.URL, adminClient)}
					var schemaResp resource.SchemaResponse
					r.Schema(ctx, resource.SchemaRequest{}, &schemaResp)
					data := backupModel{ID: types.StringUnknown(), OrgName: types.StringValue("org"), ClusterName: types.StringValue("source"), Name: types.StringValue("snapshot"), BackupType: types.StringValue("Selective"), BackupMethod: types.StringValue("native-selective"), Component: types.StringValue("standalone"), RetentionPeriod: types.StringValue("1d"), Parameters: types.MapNull(types.StringType), SelectedObjectsJSON: types.StringValue(selectionExample), Status: types.StringUnknown()}
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
					if data.ID.ValueString() != "42" || data.SelectedObjectsJSON.ValueString() != selectionExample || posts != 1 {
						t.Fatalf("state %#v, posts %d", data, posts)
					}
					readStatus = 500
					read := resource.ReadResponse{State: created.State}
					r.Read(ctx, resource.ReadRequest{State: created.State}, &read)
					if !read.Diagnostics.HasError() || read.State.Raw.IsNull() {
						t.Fatal("500 must retain backup state and fail")
					}
					readStatus = 200
					del := resource.DeleteResponse{State: created.State}
					r.Delete(ctx, resource.DeleteRequest{State: created.State}, &del)
					if del.Diagnostics.HasError() {
						t.Fatal(del.Diagnostics)
					}
					read = resource.ReadResponse{State: created.State}
					r.Read(ctx, resource.ReadRequest{State: created.State}, &read)
					if read.Diagnostics.HasError() || !read.State.Raw.IsNull() {
						t.Fatal("soft-deleted history must not preserve backup state")
					}
				})
			}
		})
	}
}

func TestSelectionValidation(t *testing.T) {
	for _, input := range []string{`{}`, `null`, `[]`, `[{"name":"x"}]`, `[{"name":"x","type":"database","selected_all":true}]`, `[{"name":"x","type":"database","children":[{"type":"table"}]}]`} {
		if _, err := selectionNodes(types.StringValue(input)); err == nil {
			t.Errorf("accepted %s", input)
		}
	}
	if _, err := selectionNodes(types.StringValue(selectionExample)); err != nil {
		t.Fatal(err)
	}
}
func TestDataProtectionPolling(t *testing.T) {
	for _, status := range []string{"Failed", "Deleting", "unexpected"} {
		if err := pollDataProtection(context.Background(), time.Millisecond, func() (string, string, error) { return status, "reason", nil }); err == nil {
			t.Fatalf("accepted %s", status)
		}
	}
	calls := 0
	if err := pollDataProtection(context.Background(), time.Millisecond, func() (string, string, error) {
		calls++
		if calls == 1 {
			return "Running", "", nil
		}
		return "Completed", "", nil
	}); err != nil || calls != 2 {
		t.Fatalf("calls %d: %v", calls, err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	if err := pollDataProtection(ctx, time.Millisecond, func() (string, string, error) { t.Fatal("called after cancellation"); return "", "", nil }); err != context.Canceled {
		t.Fatal(err)
	}
}

func TestActiveBackupPaginationAndListFailure(t *testing.T) {
	for _, adminClient := range []bool{true, false} {
		t.Run(map[bool]string{true: "admin", false: "public"}[adminClient], func(t *testing.T) {
			fail := false
			pages := []string{}
			server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				w.Header().Set("Content-Type", "application/json")
				if fail {
					w.WriteHeader(503)
					w.Write([]byte(`{}`))
					return
				}
				page := r.URL.Query().Get("page")
				pages = append(pages, page)
				items := []json.RawMessage{}
				if page == "1" {
					for i := 0; i < 100; i++ {
						items = append(items, json.RawMessage(strings.Replace(backupResponse, `"id":"42"`, `"id":"99"`, 1)))
					}
				} else {
					items = append(items, json.RawMessage(backupResponse))
				}
				json.NewEncoder(w).Encode(map[string]interface{}{"items": items})
			}))
			defer server.Close()
			r := BackupResource{client: backupTestClient(t, server.URL, adminClient)}
			data := backupModel{ID: types.StringValue("42"), OrgName: types.StringValue("org"), ClusterName: types.StringValue("source")}
			apiCtx, cancel := operationContext(context.Background(), r.client)
			defer cancel()
			if found, err := r.backupExists(apiCtx, &data); err != nil || !found || strings.Join(pages, ",") != "1,2" {
				t.Fatalf("found=%v pages=%v error=%v", found, pages, err)
			}
			fail = true
			if _, err := r.backupExists(apiCtx, &data); err == nil {
				t.Fatal("a failed list must not report absence")
			}
		})
	}
}
