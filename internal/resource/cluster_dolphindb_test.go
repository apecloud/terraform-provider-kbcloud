package resource

import (
	"context"
	"testing"

	"github.com/hashicorp/terraform-plugin-framework/types"

	mytypes "github.com/apecloud/terraform-provider-kbcloud/internal/types"
)

func TestDolphinDBTopologiesAndCreatePayload(t *testing.T) {
	for mode, names := range map[string][]string{"standalone": {"standalone"}, "integrated": {"controller", "datanode"}, "separated": {"controller", "datanode", "computenode"}} {
		t.Run(mode, func(t *testing.T) {
			var components []mytypes.ComponentsResourceModel
			for _, name := range names {
				c := mytypes.ComponentsResourceModel{Component: types.StringValue(name), ClassCode: types.StringValue("dolphindb." + mode + "." + name + ".1c2g.general"), Replicas: types.Int64Value(1), SkipResourceConstraints: types.BoolValue(true)}
				c.Volumes = types.ListNull(types.ObjectType{AttrTypes: mytypes.VolumesResourceModel{}.AttributeTypes()})
				components = append(components, c)
			}
			values, d := types.ListValueFrom(context.Background(), types.ObjectType{AttrTypes: mytypes.ComponentsResourceModel{}.AttributeTypes()}, components)
			if d.HasError() {
				t.Fatal(d)
			}
			plan := mytypes.ClustersResourceModel{Engine: types.StringValue("dolphindb"), Mode: types.StringValue(mode), Components: values}
			if d := validateDolphinDB(context.Background(), &plan); d.HasError() {
				t.Fatal(d)
			}
			body, d := clusterResourceToClusterCreate(context.Background(), &plan)
			if d.HasError() {
				t.Fatal(d)
			}
			if len(body.Components) != len(names) {
				t.Fatal("component count changed")
			}
			for i, c := range body.Components {
				if c.Component != names[i] || !c.GetSkipResourceConstraints() || c.GetReplicas() != 1 {
					t.Fatalf("component mapping lost: %+v", c)
				}
			}
			components[0].ClassCode = types.StringNull()
			plan.Components, _ = types.ListValueFrom(context.Background(), types.ObjectType{AttrTypes: mytypes.ComponentsResourceModel{}.AttributeTypes()}, components)
			if d := validateDolphinDB(context.Background(), &plan); !d.HasError() {
				t.Fatal("missing class_code accepted")
			}
		})
	}
}

func TestDolphinDBRejectsUnsupportedInPlaceVersionChange(t *testing.T) {
	state := mytypes.ClustersResourceModel{Engine: types.StringValue("dolphindb"), Version: types.StringValue("2.0.19")}
	plan := state
	plan.Version = types.StringValue("3.0.5")
	if d := validateDolphinDBUpdate(&plan, &state); !d.HasError() {
		t.Fatal("unsupported upgrade silently accepted")
	}
	plan = state
	if d := validateDolphinDBUpdate(&plan, &state); d.HasError() {
		t.Fatal(d)
	}
}
