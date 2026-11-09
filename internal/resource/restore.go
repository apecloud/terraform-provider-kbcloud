package resource

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/apecloud/kb-cloud-client-go/api/kbcloud"
	"github.com/apecloud/kb-cloud-client-go/api/kbcloud/admin"
	"github.com/hashicorp/terraform-plugin-framework/path"
	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/mapplanmodifier"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/planmodifier"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/stringplanmodifier"
	"github.com/hashicorp/terraform-plugin-framework/types"

	"github.com/apecloud/terraform-provider-kbcloud/internal/client"
)

// RestoreResource manages one restoration into an existing running cluster.
// Destroy only removes the operation object; it cannot undo restored data.
type RestoreResource struct{ client *client.Client }
type restoreModel struct {
	ID                  types.String `tfsdk:"id"`
	OrgName             types.String `tfsdk:"org_name"`
	ClusterName         types.String `tfsdk:"cluster_name"`
	BackupName          types.String `tfsdk:"backup_name"`
	Component           types.String `tfsdk:"component"`
	Parameters          types.Map    `tfsdk:"parameters"`
	SelectedObjectsJSON types.String `tfsdk:"selected_objects_json"`
	Status              types.String `tfsdk:"status"`
}

func NewRestoreResource() resource.Resource { return &RestoreResource{} }
func (r *RestoreResource) Metadata(_ context.Context, req resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_restore"
}
func (r *RestoreResource) Schema(_ context.Context, _ resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{Description: "One restore operation into a running cluster in the backup's environment and namespace. Creation waits for Completed. Destroy removes the restore object, never restored data. Changed inputs replace and rerun the operation; review plans carefully.", Attributes: map[string]schema.Attribute{
		"id":                    schema.StringAttribute{Computed: true, Description: "Restore operation name.", PlanModifiers: []planmodifier.String{stringplanmodifier.UseStateForUnknown()}},
		"org_name":              immutableString("Organization containing the target cluster.", true, false),
		"cluster_name":          immutableString("Target running cluster name. Use a separate empty cluster for full restores.", true, false),
		"backup_name":           immutableString("Kubernetes backup name, such as kbcloud_backup.snapshot.name (not its numeric ID).", true, false),
		"component":             immutableString("Target component, such as standalone or datanode.", true, false),
		"parameters":            schema.MapAttribute{Optional: true, ElementType: types.StringType, Description: "Restore parameters. For native-selective, explicitly set conflict_policy = FAIL or OVERWRITE; release-2.3 defaults to OVERWRITE if omitted.", PlanModifiers: []planmodifier.Map{mapplanmodifier.RequiresReplace()}},
		"selected_objects_json": immutableString("Optional JSON selection tree. Omit to restore all data contained in the backup.", false, false),
		"status":                schema.StringAttribute{Computed: true},
	}}
}
func (r *RestoreResource) Configure(_ context.Context, req resource.ConfigureRequest, resp *resource.ConfigureResponse) {
	if req.ProviderData == nil {
		return
	}
	var ok bool
	r.client, ok = req.ProviderData.(*client.Client)
	if !ok {
		resp.Diagnostics.AddError("Unexpected resource client", fmt.Sprintf("Expected *client.Client, got %T", req.ProviderData))
	}
}
func (r *RestoreResource) ValidateConfig(ctx context.Context, req resource.ValidateConfigRequest, resp *resource.ValidateConfigResponse) {
	var data restoreModel
	resp.Diagnostics.Append(req.Config.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() || data.SelectedObjectsJSON.IsUnknown() {
		return
	}
	if _, err := selectionNodes(data.SelectedObjectsJSON); err != nil {
		resp.Diagnostics.AddAttributeError(path.Root("selected_objects_json"), "Invalid selection", err.Error())
	}
}

func (r *RestoreResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var data restoreModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}
	body := admin.Restore{ClusterName: data.ClusterName.ValueString(), BackupName: data.BackupName.ValueString(), ComponentName: data.Component.ValueStringPointer()}
	if !data.Parameters.IsNull() {
		resp.Diagnostics.Append(data.Parameters.ElementsAs(ctx, &body.Parameters, false)...)
	}
	nodes, err := selectionNodes(data.SelectedObjectsJSON)
	body.SelectedObjects = nodes
	if err != nil {
		resp.Diagnostics.AddError("Invalid selection", err.Error())
	}
	if resp.Diagnostics.HasError() {
		return
	}
	apiCtx, cancel := operationContext(ctx, r.client)
	defer cancel()
	if err := waitForRunningCluster(apiCtx, r.client, data.OrgName.ValueString(), data.ClusterName.ValueString()); err != nil {
		resp.Diagnostics.AddError("Target cluster is not ready", err.Error())
		return
	}
	result, err := r.createRestore(apiCtx, &data, body)
	if err != nil {
		resp.Diagnostics.AddError("Create restore failed", err.Error())
		return
	}
	if result.GetName() == "" {
		resp.Diagnostics.AddError("Missing restore name", "The API accepted the restore but returned no operation name.")
		return
	}
	data.ID = types.StringValue(result.GetName())
	data.Status = types.StringValue(restorePhase(result))
	resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
	err = pollDataProtection(apiCtx, 5*time.Second, func() (string, string, error) {
		restored, found, err := r.getRestore(apiCtx, &data)
		if err != nil {
			return "", "", err
		}
		// The initial response precedes the control-plane restore record.
		if !found {
			return "Pending", "", nil
		}
		data.Status = types.StringValue(restorePhase(restored))
		return data.Status.ValueString(), restoreFailure(restored), nil
	})
	resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
	if err != nil {
		resp.Diagnostics.AddError("Restore did not complete", fmt.Sprintf("Restore %s: %s", data.ID.ValueString(), err))
	}
}
func (r *RestoreResource) createRestore(ctx context.Context, data *restoreModel, body admin.Restore) (admin.Restore, error) {
	if r.client.IsAdminClient() {
		result, resp, err := admin.NewRestoreApi(r.client.AdminClient()).DoRestore(ctx, data.OrgName.ValueString(), data.ClusterName.ValueString(), body)
		return result, apiError(resp, err)
	}
	var publicBody kbcloud.Restore
	if err := convertAPI(body, &publicBody); err != nil {
		return admin.Restore{}, err
	}
	result, resp, err := kbcloud.NewRestoreApi(r.client.Client()).DoRestore(ctx, data.OrgName.ValueString(), data.ClusterName.ValueString(), publicBody)
	if err = apiError(resp, err); err != nil {
		return admin.Restore{}, err
	}
	var restored admin.Restore
	err = convertAPI(result, &restored)
	return restored, err
}
func (r *RestoreResource) getRestore(ctx context.Context, data *restoreModel) (admin.Restore, bool, error) {
	var result admin.RestoreList
	if r.client.IsAdminClient() {
		var resp *http.Response
		var err error
		result, resp, err = admin.NewRestoreApi(r.client.AdminClient()).ListClusterRestore(ctx, data.OrgName.ValueString(), data.ClusterName.ValueString())
		if err = apiError(resp, err); err != nil {
			return admin.Restore{}, false, err
		}
	} else {
		public, resp, err := kbcloud.NewRestoreApi(r.client.Client()).ListClusterRestore(ctx, data.OrgName.ValueString(), data.ClusterName.ValueString())
		if err = apiError(resp, err); err != nil {
			return admin.Restore{}, false, err
		}
		if err = convertAPI(public, &result); err != nil {
			return admin.Restore{}, false, err
		}
	}
	for _, item := range result.Items {
		if item.GetName() == data.ID.ValueString() {
			return item, true, nil
		}
	}
	return admin.Restore{}, false, nil
}
func restorePhase(r admin.Restore) string {
	if r.Status == nil {
		return ""
	}
	return r.Status.GetPhase()
}
func restoreFailure(r admin.Restore) string {
	if r.Status != nil {
		for _, condition := range r.Status.Conditions {
			if condition.GetStatus() == "False" && condition.GetMessage() != "" {
				return condition.GetMessage()
			}
		}
	}
	return "See restore logs in the console."
}
func (r *RestoreResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var data restoreModel
	resp.Diagnostics.Append(req.State.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}
	apiCtx, cancel := operationContext(ctx, r.client)
	defer cancel()
	result, found, err := r.getRestore(apiCtx, &data)
	if err != nil {
		resp.Diagnostics.AddError("Read restore failed", err.Error())
		return
	}
	if !found {
		resp.Diagnostics.AddWarning("Restore history missing", "The API no longer lists this restore. State was retained to avoid automatically replaying the operation. Remove it from configuration if no longer needed, or explicitly replace it to run recovery again.")
		return
	}
	data.Status = types.StringValue(restorePhase(result))
	resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}
func (r *RestoreResource) Update(_ context.Context, _ resource.UpdateRequest, resp *resource.UpdateResponse) {
	resp.Diagnostics.AddError("Restore is immutable", "Changing restore inputs requires replacement and reruns recovery.")
}
func (r *RestoreResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var data restoreModel
	resp.Diagnostics.Append(req.State.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}
	apiCtx, cancel := operationContext(ctx, r.client)
	defer cancel()
	var response *http.Response
	var err error
	if r.client.IsAdminClient() {
		response, err = admin.NewRestoreApi(r.client.AdminClient()).DeleteRestoreObject(apiCtx, data.OrgName.ValueString(), data.ClusterName.ValueString(), data.ID.ValueString())
	} else {
		response, err = kbcloud.NewRestoreApi(r.client.Client()).DeleteRestoreObject(apiCtx, data.OrgName.ValueString(), data.ClusterName.ValueString(), data.ID.ValueString())
	}
	if response != nil && response.StatusCode == http.StatusNotFound {
		return
	}
	if err = apiError(response, err); err != nil {
		resp.Diagnostics.AddError("Delete restore object failed", err.Error())
	}
}

var _ resource.ResourceWithValidateConfig = (*RestoreResource)(nil)
