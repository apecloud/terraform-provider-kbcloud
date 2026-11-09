package resource

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"reflect"
	"testing"

	"github.com/hashicorp/terraform-plugin-framework/types"

	"github.com/apecloud/terraform-provider-kbcloud/internal/client"
	mytypes "github.com/apecloud/terraform-provider-kbcloud/internal/types"
)

func parameterOptions(t *testing.T, entries ...mytypes.InitOptionsResourceModel) types.List {
	t.Helper()
	if entries == nil {
		entries = []mytypes.InitOptionsResourceModel{}
	}
	result, diags := types.ListValueFrom(context.Background(), types.ObjectType{AttrTypes: mytypes.InitOptionsResourceModel{}.AttributeTypes()}, entries)
	if diags.HasError() {
		t.Fatal(diags)
	}
	return result
}
func parameterOption(t *testing.T, component, file string, params map[string]string) mytypes.InitOptionsResourceModel {
	t.Helper()
	values, diags := types.MapValueFrom(context.Background(), types.StringType, params)
	if diags.HasError() {
		t.Fatal(diags)
	}
	return mytypes.InitOptionsResourceModel{Component: types.StringValue(component), ConfigFileName: types.StringValue(file), InitParams: values}
}

// Exercise both SDK paths and assert the actual HTTP payloads, including two
// components with the same parameter name but different intended values.
func TestReconfigureDolphinDBComponents(t *testing.T) {
	for _, adminClient := range []bool{true, false} {
		t.Run(map[bool]string{true: "admin", false: "public"}[adminClient], func(t *testing.T) {
			var bodies []map[string]interface{}
			server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				if r.Method == http.MethodGet {
					w.Header().Set("Content-Type", "application/json")
					_, _ = w.Write([]byte(`{"taskId":"test-task","taskName":"reconfigure","taskType":"Reconfigure","status":"Succeed","createdAt":"2026-11-09T00:00:00Z","updatedAt":"2026-11-09T00:00:00Z"}`))
					return
				}
				if r.Method != http.MethodPost {
					t.Errorf("unexpected method %s", r.Method)
				}
				var body map[string]interface{}
				if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
					t.Error(err)
				}
				bodies = append(bodies, body)
				w.Header().Set("Content-Type", "application/json")
				_, _ = w.Write([]byte(`{"taskId":"test-task"}`))
			}))
			defer server.Close()
			config := mytypes.ProviderSchema{APIUrl: types.StringValue(server.URL)}
			if adminClient {
				config.AdminAPIKey = types.StringValue("test")
				config.AdminAPISecret = types.StringValue("test")
			} else {
				config.APIKey = types.StringValue("test")
				config.APISecret = types.StringValue("test")
			}
			apiClient, err := client.New(config)
			if err != nil {
				t.Fatal(err)
			}
			state := mytypes.ClustersResourceModel{Engine: types.StringValue("dolphindb"), OrgName: types.StringValue("test"), Name: types.StringValue("test")}
			state.InitOptions = parameterOptions(t,
				parameterOption(t, "controller", "", map[string]string{"maxConnections": "100", "workerNum": "2"}),
				parameterOption(t, "datanode", "", map[string]string{"maxConnections": "100"}),
				parameterOption(t, "computenode", "", map[string]string{"maxConnections": "100"}),
			)
			plan := state
			plan.InitOptions = parameterOptions(t,
				parameterOption(t, "computenode", "dolphindb.cfg", map[string]string{"maxConnections": "300"}),
				parameterOption(t, "controller", "", map[string]string{"maxConnections": "100", "workerNum": "2"}),
				parameterOption(t, "datanode", "", map[string]string{"maxConnections": "200"}),
			)
			resource := ClusterResource{client: apiClient}
			if diags := resource.doReconfigure(context.Background(), &plan, &state); diags.HasError() {
				t.Fatal(diags)
			}
			want := []map[string]interface{}{
				{"component": "computenode", "configFileName": "dolphindb.cfg", "parameters": map[string]interface{}{"maxConnections": "300"}},
				{"component": "datanode", "configFileName": "dolphindb.cfg", "parameters": map[string]interface{}{"maxConnections": "200"}},
			}
			if !reflect.DeepEqual(bodies, want) {
				t.Fatalf("requests = %#v, want %#v", bodies, want)
			}
			if diags := resource.doReconfigure(context.Background(), &plan, &plan); diags.HasError() {
				t.Fatal(diags)
			}
			if len(bodies) != 2 {
				t.Fatal("no-op sent extra requests")
			}
		})
	}
}

func TestParameterRemovalFailsBeforeRequests(t *testing.T) {
	state := mytypes.ClustersResourceModel{Engine: types.StringValue("dolphindb"), InitOptions: parameterOptions(t, parameterOption(t, "datanode", "", map[string]string{"workerNum": "4"}))}
	plan := state
	plan.InitOptions = parameterOptions(t, parameterOption(t, "datanode", "", map[string]string{}))
	requests, diags := parameterRequests(context.Background(), &plan, &state)
	if !diags.HasError() || len(requests) != 0 {
		t.Fatalf("removing a parameter silently succeeded: %v, %v", requests, diags)
	}
}

func TestRefreshUsesLiveComponentParameters(t *testing.T) {
	for _, adminClient := range []bool{true, false} {
		t.Run(map[bool]string{true: "admin", false: "public"}[adminClient], func(t *testing.T) {
			server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				component := r.URL.Query().Get("component")
				value := map[string]string{"datanode": "3", "computenode": "4"}[component]
				if value == "" {
					t.Errorf("unexpected component %q", component)
				}
				w.Header().Set("Content-Type", "application/json")
				_ = json.NewEncoder(w).Encode(map[string]interface{}{"engine": "dolphindb", "component": component, "items": []interface{}{map[string]interface{}{"fileName": "dolphindb.cfg", "props": []interface{}{
					map[string]interface{}{"name": "workerNum", "type": "integer", "needRestart": true, "immutable": false, "value": value},
					map[string]interface{}{"name": "unmanaged", "type": "integer", "needRestart": false, "immutable": false, "value": "100"},
				}}}})
			}))
			defer server.Close()
			r := ClusterResource{client: testAPIClient(t, server.URL, adminClient)}
			data := mytypes.ClustersResourceModel{Engine: types.StringValue("dolphindb"), OrgName: types.StringValue("test"), Name: types.StringValue("test"), InitOptions: parameterOptions(t,
				parameterOption(t, "datanode", "dolphindb.cfg", map[string]string{"workerNum": "2"}),
				parameterOption(t, "computenode", "dolphindb.cfg", map[string]string{"workerNum": "2"}),
			)}
			if d := r.refreshConfiguredParameters(context.Background(), &data); d.HasError() {
				t.Fatal(d)
			}
			want := parameterOptions(t,
				parameterOption(t, "datanode", "dolphindb.cfg", map[string]string{"workerNum": "3"}),
				parameterOption(t, "computenode", "dolphindb.cfg", map[string]string{"workerNum": "4"}),
			)
			if !data.InitOptions.Equal(want) {
				t.Fatalf("live values or component boundaries lost: %s", data.InitOptions)
			}
		})
	}
}
