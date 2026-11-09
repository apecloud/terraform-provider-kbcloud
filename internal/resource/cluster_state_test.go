package resource

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/tfsdk"
	"github.com/hashicorp/terraform-plugin-framework/types"

	"github.com/apecloud/terraform-provider-kbcloud/internal/client"
	mytypes "github.com/apecloud/terraform-provider-kbcloud/internal/types"
)

func testClusterState(t *testing.T) tfsdk.State {
	t.Helper()
	ctx := context.Background()
	var model mytypes.ClustersResourceModel
	if d := model.RefreshFromAPI(ctx, map[string]interface{}{"id": "cluster-id", "orgName": "test", "name": "dolphindb", "engine": "dolphindb", "environmentName": "test"}); d.HasError() {
		t.Fatal(d)
	}
	model.ID = types.StringValue("cluster-id")
	model.InitOptions = types.ListNull(types.ObjectType{AttrTypes: mytypes.InitOptionsResourceModel{}.AttributeTypes()})
	state := tfsdk.State{Schema: ClustersResourceSchema()}
	if d := state.Set(ctx, &model); d.HasError() {
		t.Fatal(d)
	}
	return state
}

func testAPIClient(t *testing.T, url string, admin bool) *client.Client {
	t.Helper()
	cfg := mytypes.ProviderSchema{APIUrl: types.StringValue(url)}
	if admin {
		cfg.AdminAPIKey = types.StringValue("test")
		cfg.AdminAPISecret = types.StringValue("test")
	} else {
		cfg.APIKey = types.StringValue("test")
		cfg.APISecret = types.StringValue("test")
	}
	c, err := client.New(cfg)
	if err != nil {
		t.Fatal(err)
	}
	return c
}

func TestReadPreservesErrorsAndRemovesOnlyMissingResources(t *testing.T) {
	for _, status := range []int{http.StatusForbidden, http.StatusInternalServerError, http.StatusNotFound} {
		t.Run(http.StatusText(status), func(t *testing.T) {
			server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				w.Header().Set("Content-Type", "application/json")
				w.WriteHeader(status)
				_, _ = w.Write([]byte(`{"message":"test error"}`))
			}))
			defer server.Close()
			r := ClusterResource{client: testAPIClient(t, server.URL, true)}
			state := testClusterState(t)
			response := resource.ReadResponse{State: state}
			r.Read(context.Background(), resource.ReadRequest{State: state}, &response)
			if status == 404 {
				if response.Diagnostics.HasError() || !response.State.Raw.IsNull() {
					t.Fatal("404 must remove resource", response.Diagnostics)
				}
			} else if !response.Diagnostics.HasError() || response.State.Raw.IsNull() {
				t.Fatal("API errors must preserve state and fail the read", response.Diagnostics)
			}
		})
	}
}

func TestPublicCreateReadsReturnedCluster(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var body map[string]interface{}
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			t.Error(err)
		}
		body["id"] = "new-id"
		body["displayName"] = "server-generated"
		body["mode"] = "standalone"
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(body)
	}))
	defer server.Close()
	r := ClusterResource{client: testAPIClient(t, server.URL, false)}
	state := testClusterState(t)
	response := resource.CreateResponse{State: tfsdk.State{Schema: state.Schema}}
	r.Create(context.Background(), resource.CreateRequest{Plan: tfsdk.Plan{Schema: state.Schema, Raw: state.Raw}}, &response)
	if response.Diagnostics.HasError() {
		t.Fatal(response.Diagnostics)
	}
	var model mytypes.ClustersResourceModel
	if d := response.State.Get(context.Background(), &model); d.HasError() {
		t.Fatal(d)
	}
	if model.ID.ValueString() != "new-id" || model.DisplayName.ValueString() != "server-generated" {
		t.Fatalf("state did not use API response: %v %v", model.ID, model.DisplayName)
	}
}

func TestInitOptionsSurviveClusterSnapshot(t *testing.T) {
	configured := parameterOptions(t, parameterOption(t, "datanode", "dolphindb.cfg", map[string]string{"workerNum": "4"}))
	model := mytypes.ClustersResourceModel{InitOptions: configured}
	old := []interface{}{map[string]interface{}{"component": "datanode", "initParams": map[string]interface{}{"workerNum": "2"}}}
	if d := model.RefreshFromAPI(context.Background(), map[string]interface{}{"initOptions": old}); d.HasError() {
		t.Fatal(d)
	}
	if !model.InitOptions.Equal(configured) {
		t.Fatal("creation-time snapshot overwrote managed parameters")
	}
	model.InitOptions = parameterOptions(t)
	model.RefreshFromAPI(context.Background(), map[string]interface{}{})
	if model.InitOptions.IsNull() {
		t.Fatal("empty configured list became null")
	}
}

func TestRefreshPreservesComponentAndVolumeOrder(t *testing.T) {
	ctx := context.Background()
	var model mytypes.ClustersResourceModel
	snapshot := func(order []string) map[string]interface{} {
		components := []interface{}{}
		for _, name := range order {
			components = append(components, map[string]interface{}{"component": name, "replicas": float64(1), "volumes": []interface{}{map[string]interface{}{"name": "log", "storage": float64(1)}, map[string]interface{}{"name": "data", "storage": float64(10)}}})
		}
		if order[0] == "controller" {
			for _, item := range components {
				v := item.(map[string]interface{})["volumes"].([]interface{})
				v[0], v[1] = v[1], v[0]
			}
		}
		return map[string]interface{}{"components": components}
	}
	if d := model.RefreshFromAPI(ctx, snapshot([]string{"computenode", "controller", "datanode"})); d.HasError() {
		t.Fatal(d)
	}
	before := model.Components
	if d := refreshClusterModel(ctx, &model, snapshot([]string{"controller", "datanode", "computenode"})); d.HasError() {
		t.Fatal(d)
	}
	if !model.Components.Equal(before) {
		t.Fatal("API order changed Terraform state")
	}
}
