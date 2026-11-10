package resource

import (
	"context"

	"github.com/hashicorp/terraform-plugin-framework/diag"

	mytypes "github.com/apecloud/terraform-provider-kbcloud/internal/types"
)

// The API can return components and volumes in a different order. Preserve the
// configured list order, matching by identity before the generated model refresh.
func refreshClusterModel(ctx context.Context, data *mytypes.ClustersResourceModel, apiData map[string]interface{}) diag.Diagnostics {
	var diags diag.Diagnostics
	var components []mytypes.ComponentsResourceModel
	if !data.Components.IsNull() && !data.Components.IsUnknown() {
		diags.Append(data.Components.ElementsAs(ctx, &components, false)...)
	}
	if diags.HasError() {
		return diags
	}
	var names []string
	for _, component := range components {
		names = append(names, component.Component.ValueString())
	}
	if remote, ok := apiData["components"].([]interface{}); ok {
		remote = orderByNames(remote, "component", names)
		for _, item := range remote {
			object, ok := item.(map[string]interface{})
			if !ok {
				continue
			}
			for _, component := range components {
				if object["component"] != component.Component.ValueString() {
					continue
				}
				var volumes []mytypes.VolumesResourceModel
				if !component.Volumes.IsNull() && !component.Volumes.IsUnknown() {
					diags.Append(component.Volumes.ElementsAs(ctx, &volumes, false)...)
				}
				var volumeNames []string
				for _, volume := range volumes {
					volumeNames = append(volumeNames, volume.Name.ValueString())
				}
				if remoteVolumes, ok := object["volumes"].([]interface{}); ok {
					object["volumes"] = orderByNames(remoteVolumes, "name", volumeNames)
				}
			}
		}
		apiData["components"] = remote
	}
	if !diags.HasError() {
		diags.Append(data.RefreshFromAPI(ctx, apiData)...)
	}
	return diags
}

func orderByNames(items []interface{}, key string, names []string) []interface{} {
	ordered := make([]interface{}, 0, len(items))
	used := make([]bool, len(items))
	for _, name := range names {
		for i, item := range items {
			if object, ok := item.(map[string]interface{}); ok && !used[i] && object[key] == name {
				ordered = append(ordered, item)
				used[i] = true
				break
			}
		}
	}
	for i, item := range items {
		if !used[i] {
			ordered = append(ordered, item)
		}
	}
	return ordered
}
