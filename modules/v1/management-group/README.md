# Management Groups
This module will deploy a management group and add subscription(s) to it.

## Requirements
The principal conducting the deployment must have permissions to create resources at the tenant scope. 

More info can be found [here](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-to-tenant?tabs=azure-cli#required-access).

## Usage

### Example 1 - Management Group with tenant root as parent
``` bicep
targetScope = 'tenant'

param mgDeploymentName string = 'managementGroups${utcNow()}'

var managementGroups = [
  {
    managementGroupDisplayName: 'MyOrganisation'
    managementGroupId: 'gbl-org-mgp'
    parentManagementGroupId: ''
    subscriptionIds: []
  }
]

@batchSize(1) //processes management groups in order to ensure parent management groups are created before child management groups
module managementGroupGlobal './management-group.bicep' = [for managementGroup in managementGroups: {
  name: '${mgDeploymentName}${managementGroup.managementGroupId}'
  params: {
    managementGroupDisplayName: managementGroup.managementGroupDisplayName
    managementGroupId: managementGroup.managementGroupId
    subscriptionIds: managementGroup.subscriptionIds
    parentManagementGroupId: managementGroup.parentManagementGroupId
  }
}]
```

### Example 2 - Nested management group with subscriptions
``` bicep
targetScope = 'tenant'

param mgDeploymentName string = 'managementGroups${utcNow()}'

var managementGroups = [
  {
    managementGroupDisplayName: 'MyOrganisation'
    managementGroupId: 'gbl-org-mgp'
    parentManagementGroupId: ''
    subscriptionIds: []
  }
  {
    managementGroupDisplayName: 'Platform'
    managementGroupId: 'pfm-org-mgp'
    parentManagementGroupId: 'gbl-org-mgp'
    subscriptionIds: [
      'bd1f0a5b-4cb7-4d37-841b-9951f60b6bd2'
    ]
  }
]

@batchSize(1) //processes management groups in order to ensure parent management groups are created before child management groups
module managementGroupGlobal './management-group.bicep' = [for managementGroup in managementGroups: {
  name: '${mgDeploymentName}${managementGroup.managementGroupId}'
  params: {
    managementGroupDisplayName: managementGroup.managementGroupDisplayName
    managementGroupId: managementGroup.managementGroupId
    subscriptionIds: managementGroup.subscriptionIds
    parentManagementGroupId: managementGroup.parentManagementGroupId
  }
}]
```