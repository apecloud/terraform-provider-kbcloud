package resource

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/apecloud/kb-cloud-client-go/api/kbcloud"
	"github.com/apecloud/kb-cloud-client-go/api/kbcloud/admin"
	"github.com/hashicorp/terraform-plugin-framework/diag"
	"github.com/hashicorp/terraform-plugin-framework/types"

	mytypes "github.com/apecloud/terraform-provider-kbcloud/internal/types"
	"github.com/apecloud/terraform-provider-kbcloud/internal/utils"
)

type parameterTarget struct {
	component string
	file      string
}

// parameterRequests preserves the component and configuration file boundaries of
// init_options. Removing a key cannot reset its database value: callers must set
// the desired default explicitly instead of silently forgetting the old value.
func parameterRequests(ctx context.Context, data, state *mytypes.ClustersResourceModel) ([]admin.ReconfigureCreate, diag.Diagnostics) {
	var diags diag.Diagnostics
	if data.InitOptions.IsUnknown() || data.InitOptions.Equal(state.InitOptions) {
		return nil, diags
	}
	decode := func(value types.List) (map[parameterTarget]map[string]string, []parameterTarget) {
		result := map[parameterTarget]map[string]string{}
		var order []parameterTarget
		if value.IsNull() || value.IsUnknown() {
			return result, order
		}
		var options []mytypes.InitOptionsResourceModel
		diags.Append(value.ElementsAs(ctx, &options, false)...)
		for _, option := range options {
			component, componentDiags := parameterComponent(ctx, data, option.Component.ValueString())
			diags.Append(componentDiags...)
			if componentDiags.HasError() {
				continue
			}

			file := option.ConfigFileName.ValueString()
			if file == "" {
				file = determineConfigFileName(data.Engine.ValueString(), component)
			}
			target := parameterTarget{component: component, file: file}
			if _, exists := result[target]; exists {
				diags.AddError("Duplicate parameter configuration", fmt.Sprintf("Only one init_options entry is allowed for component %s and file %s.", component, file))
				continue
			}
			params := map[string]string{}
			if !option.InitParams.IsNull() && !option.InitParams.IsUnknown() {
				diags.Append(option.InitParams.ElementsAs(ctx, &params, false)...)
			}
			result[target] = params
			order = append(order, target)
		}
		return result, order
	}
	current, order := decode(data.InitOptions)
	previous, _ := decode(state.InitOptions)
	for target, params := range previous {
		for name := range params {
			if _, exists := current[target][name]; !exists {
				diags.AddError("Parameter removal is not supported", fmt.Sprintf("Keep %s in component %s (%s) configured with its intended default value; omitting it does not reset the database value.", name, target.component, target.file))
			}
		}
	}
	if diags.HasError() {
		return nil, diags
	}
	var requests []admin.ReconfigureCreate
	for _, target := range order {
		changed := map[string]string{}
		for name, value := range current[target] {
			old, exists := previous[target][name]
			if !exists || old != value {
				changed[name] = value
			}
		}
		if len(changed) != 0 {
			file := target.file
			requests = append(requests, admin.ReconfigureCreate{Component: target.component, ConfigFileName: &file, Parameters: changed})
		}
	}
	return requests, diags
}

func (r *ClusterResource) doReconfigure(ctx context.Context, data, state *mytypes.ClustersResourceModel) diag.Diagnostics {
	requests, diags := parameterRequests(ctx, data, state)
	if diags.HasError() {
		return diags
	}
	for _, body := range requests {
		var response *http.Response
		var err error
		var taskID string
		if r.client.IsAdminClient() {
			var task admin.OpsRequestName
			task, response, err = admin.NewOpsrequestApi(r.client.AdminClient()).ReconfigureCluster(r.client.AdminCtx(), data.OrgName.ValueString(), data.Name.ValueString(), body)
			taskID = task.TaskId
		} else {
			var task kbcloud.OpsRequestName
			task, response, err = kbcloud.NewOpsrequestApi(r.client.Client()).ReconfigureCluster(r.client.Ctx(), data.OrgName.ValueString(), data.Name.ValueString(), kbcloud.ReconfigureCreate{
				Component: body.Component, ConfigFileName: body.ConfigFileName, Parameters: body.Parameters,
			})
			taskID = task.TaskId
		}
		if err != nil || !utils.IsHTTPSuccess(response) {
			diags.AddError("Unable to reconfigure cluster", fmt.Sprintf("Component %s: %v %s", body.Component, err, utils.GetRespErrorDetail(response)))
			return diags
		}
		diags.Append(r.waitForTask(ctx, data.OrgName.ValueString(), taskID)...)
		if diags.HasError() {
			return diags
		}
	}
	return diags
}

// determineConfigFileName determines the configuration file name based on engine and component
func determineConfigFileName(engine string, component string) string {
	// Config file names for different engines (from engineoption/*.json)
	// These are the configFileName values defined in the parameters.configSpecs
	configFileNames := map[string]map[string]string{
		"mysql": {
			"mysql": "my.cnf",
		},
		"postgresql": {
			"postgresql": "postgresql.conf",
		},
		"mongodb": {
			"mongodb":             "mongodb.conf",
			"mongo-shard":         "mongodb.conf",
			"mongo-config-server": "mongodb.conf",
			"mongo-mongos":        "mongos.conf",
		},
		"redis": {
			"redis":          "redis.conf",
			"redis-cluster":  "redis.conf",
			"redis-sentinel": "redis.conf",
		},
		"kafka": {
			"kafka-combine":    "server.properties",
			"kafka-broker":     "server.properties",
			"kafka-controller": "server.properties",
			"kafka-zookeeper":  "zookeeper.properties",
		},
		"dolphindb": {
			"standalone":  "dolphindb.cfg",
			"controller":  "dolphindb.cfg",
			"datanode":    "dolphindb.cfg",
			"computenode": "dolphindb.cfg",
		},
		"mssql": {
			"mssql": "mssql.conf",
		},
	}

	// Try to find specific config file name
	if engineConfigs, ok := configFileNames[engine]; ok {
		if configName, ok := engineConfigs[component]; ok {
			return configName
		}
	}

	// Fallback: use component name with .conf suffix
	return component + ".conf"
}

// refreshConfiguredParameters reads live values instead of the cluster's
// creation-time initOptions snapshot, and manages only explicitly selected keys.
func (r *ClusterResource) refreshConfiguredParameters(ctx context.Context, data *mytypes.ClustersResourceModel) diag.Diagnostics {
	var diags diag.Diagnostics
	if data.InitOptions.IsNull() || data.InitOptions.IsUnknown() || len(data.InitOptions.Elements()) == 0 {
		return diags
	}
	var options []mytypes.InitOptionsResourceModel
	diags.Append(data.InitOptions.ElementsAs(ctx, &options, false)...)
	if diags.HasError() {
		return diags
	}
	cache := map[string][]admin.ParameterItem{}
	for i := range options {
		option := &options[i]
		if option.InitParams.IsNull() || option.InitParams.IsUnknown() || len(option.InitParams.Elements()) == 0 {
			continue
		}
		component, componentDiags := parameterComponent(ctx, data, option.Component.ValueString())
		diags.Append(componentDiags...)
		if componentDiags.HasError() {
			return diags
		}
		file := option.ConfigFileName.ValueString()
		if file == "" {
			file = determineConfigFileName(data.Engine.ValueString(), component)
		}
		items, ok := cache[component]
		if !ok {
			var response *http.Response
			var err error
			if r.client.IsAdminClient() {
				var result admin.ParameterList
				result, response, err = admin.NewParameterApi(r.client.AdminClient()).ListParameterProps(r.client.AdminCtx(), data.OrgName.ValueString(), data.Name.ValueString(), *admin.NewListParameterPropsOptionalParameters().WithComponent(component))
				items = result.Items
			} else {
				var result kbcloud.ParameterList
				result, response, err = kbcloud.NewParameterApi(r.client.Client()).ListParameterProps(r.client.Ctx(), data.OrgName.ValueString(), data.Name.ValueString(), *kbcloud.NewListParameterPropsOptionalParameters().WithComponent(component))
				if err == nil {
					raw, marshalErr := json.Marshal(result.Items)
					if marshalErr != nil {
						err = marshalErr
					} else {
						err = json.Unmarshal(raw, &items)
					}
				}
			}
			if err != nil || !utils.IsHTTPSuccess(response) {
				diags.AddError("Unable to read cluster parameters", fmt.Sprintf("Component %s: %v %s", component, err, utils.GetRespErrorDetail(response)))
				return diags
			}
			cache[component] = items
		}
		actual := map[string]string{}
		for _, item := range items {
			if item.GetFileName() != file {
				continue
			}
			for _, prop := range append(item.Props, item.AdditionalProps...) {
				if prop.Value != nil {
					actual[prop.Name] = fmt.Sprint(prop.Value)
				}
			}
		}
		configured := map[string]string{}
		diags.Append(option.InitParams.ElementsAs(ctx, &configured, false)...)
		for name := range configured {
			value, found := actual[name]
			if !found {
				diags.AddError("Cluster parameter was not returned", fmt.Sprintf("Component %s, file %s, parameter %s.", component, file, name))
				continue
			}
			configured[name] = value
		}
		values, d := types.MapValueFrom(ctx, types.StringType, configured)
		diags.Append(d...)
		option.InitParams = values
	}
	if !diags.HasError() {
		values, d := types.ListValueFrom(ctx, types.ObjectType{AttrTypes: mytypes.InitOptionsResourceModel{}.AttributeTypes()}, options)
		diags.Append(d...)
		data.InitOptions = values
	}
	return diags
}

func parameterComponent(ctx context.Context, data *mytypes.ClustersResourceModel, name string) (string, diag.Diagnostics) {
	var diags diag.Diagnostics
	if name != "" {
		return name, diags
	}
	var components []mytypes.ComponentsResourceModel
	if !data.Components.IsNull() && !data.Components.IsUnknown() {
		diags.Append(data.Components.ElementsAs(ctx, &components, false)...)
	}
	if len(components) != 1 {
		diags.AddError("Missing parameter component", "Each init_options entry must name its component for a cluster with multiple components.")
		return "", diags
	}
	return components[0].Component.ValueString(), diags
}
