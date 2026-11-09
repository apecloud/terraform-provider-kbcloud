package resource

import (
	"context"
	"fmt"
	"slices"

	"github.com/hashicorp/terraform-plugin-framework/attr"
	"github.com/hashicorp/terraform-plugin-framework/diag"
	"github.com/hashicorp/terraform-plugin-framework/resource"

	mytypes "github.com/apecloud/terraform-provider-kbcloud/internal/types"
)

func (r *ClusterResource) ValidateConfig(ctx context.Context, req resource.ValidateConfigRequest, resp *resource.ValidateConfigResponse) {
	var data mytypes.ClustersResourceModel
	resp.Diagnostics.Append(req.Config.Get(ctx, &data)...)
	if !resp.Diagnostics.HasError() {
		resp.Diagnostics.Append(validateDolphinDB(ctx, &data)...)
	}
}

func validateDolphinDB(ctx context.Context, data *mytypes.ClustersResourceModel) diag.Diagnostics {
	var diags diag.Diagnostics
	if data.Engine.ValueString() != "dolphindb" {
		return diags
	}
	topology := map[string][]string{
		"standalone": {"standalone"},
		"integrated": {"controller", "datanode"},
		"separated":  {"controller", "datanode", "computenode"},
	}
	if data.Mode.IsUnknown() {
		return diags
	}
	mode := data.Mode.ValueString()
	if mode == "" {
		mode = "standalone"
	}
	expected, ok := topology[mode]
	if !ok {
		diags.AddError("Invalid DolphinDB mode", "Use standalone, integrated or separated.")
		return diags
	}
	if data.Components.IsUnknown() {
		return diags
	}
	var components []mytypes.ComponentsResourceModel
	if !data.Components.IsNull() {
		diags.Append(data.Components.ElementsAs(ctx, &components, false)...)
	}
	if diags.HasError() {
		return diags
	}
	seen := map[string]bool{}
	for _, component := range components {
		if component.Component.IsUnknown() {
			return diags
		}
		name := component.Component.ValueString()
		if !slices.Contains(expected, name) || seen[name] {
			diags.AddError("Invalid DolphinDB component", fmt.Sprintf("Mode %s requires exactly these components: %v.", mode, expected))
		}
		seen[name] = true
		if !component.ClassCode.IsUnknown() && component.ClassCode.ValueString() == "" {
			diags.AddError("DolphinDB class_code is required", fmt.Sprintf("Set class_code for %s to an available DolphinDB class. release-2.3 uses the class to apply CPU and memory limits.", name))
		}
		if !component.CompNum.IsUnknown() && component.CompNum.ValueInt64() != 0 {
			diags.AddError("DolphinDB does not use comp_num", "Use replicas for the number of DolphinDB nodes.")
		}
	}
	if len(seen) != len(expected) {
		diags.AddError("Incomplete DolphinDB topology", fmt.Sprintf("Mode %s requires exactly these components: %v.", mode, expected))
	}
	return diags
}

// These fields are creation settings, not supported DolphinDB in-place updates.
// Reject changes instead of saving the desired value without changing the API.
func validateDolphinDBUpdate(plan, state *mytypes.ClustersResourceModel) diag.Diagnostics {
	var diags diag.Diagnostics
	if plan.Engine.ValueString() != "dolphindb" && state.Engine.ValueString() != "dolphindb" {
		return diags
	}
	fields := []struct {
		name           string
		planned, prior attr.Value
	}{
		{"name", plan.Name, state.Name}, {"engine", plan.Engine, state.Engine},
		{"org_name", plan.OrgName, state.OrgName}, {"environment_name", plan.EnvironmentName, state.EnvironmentName},
		{"project", plan.Project, state.Project}, {"mode", plan.Mode, state.Mode},
		{"version", plan.Version, state.Version}, {"network_mode", plan.NetworkMode, state.NetworkMode},
		{"extra", plan.Extra, state.Extra}, {"license", plan.License, state.License},
		{"param_tpls", plan.ParamTpls, state.ParamTpls},
	}
	for _, field := range fields {
		if !field.planned.IsUnknown() && !(field.planned.IsNull() && field.prior.IsNull()) && !field.planned.Equal(field.prior) {
			diags.AddError("Unsupported DolphinDB update", fmt.Sprintf("%s is a creation setting. This provider does not support changing it in place; create a separate cluster for this change.", field.name))
		}
	}
	return diags
}

var _ resource.ResourceWithValidateConfig = (*ClusterResource)(nil)
