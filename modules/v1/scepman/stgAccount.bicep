@description('Name of the storage account')
param StorageAccountName string

@description('Location where the resources will be deployed')
param location string

@description('Whether to allow Azure Services to bypass Network Acls.')
@allowed([
  'AzureServices'
  'None'
])
param networkAclsBypass string = 'AzureServices'

@description('Set to Deny if you want to enable the firewall.')
@allowed([
  'Allow'
  'Deny'
])
param networkAclsDefaultAction string = 'Allow'

@description('An array of CIDR ranges for Storage Network ACLs.')
@metadata({
  note: 'Sample input'
  ipRules: [
    {
      action: 'Allow'
      value: 'CIDR Range'
    }
  ]
})
param ipRules array = []

@description('An array of CIDR ranges for Storage Network ACLs.')
@metadata({
  note: 'Sample input'
  resourceAccessRules: [
    {
      resourceId: '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourcegroups/example-dev-rg/providers/microsoft.operationalinsights/workspaces/example-dev-log'
      tenantId: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
    }
  ]
})
param resourceAccessRules array = []

@description('An array of CIDR ranges for Storage Network ACLs.')
@metadata({
  note: 'Sample input'
  virtualNetworkRules: [
    {
      action: 'Allow'
      id: '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/example-dev-rg/providers/Microsoft.Network/virtualNetworks/example-dev-vnet/subnets/examplesubnet'
    }
  ]
})
param virtualNetworkRules array = []


@description('IDs of Principals that shall receive table contributor rights on the storage account')
param tableContributorPrincipals array

resource StorageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: StorageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: true
    allowCrossTenantReplication: false
    allowSharedKeyAccess: false
    isHnsEnabled: false
    isNfsV3Enabled: false
    minimumTlsVersion: 'TLS1_2'
    routingPreference: {
      publishInternetEndpoints: false
      publishMicrosoftEndpoints: false
      routingChoice: 'MicrosoftRouting'
      
    }
    networkAcls: {
      bypass: networkAclsBypass
      defaultAction: networkAclsDefaultAction
      ipRules: ipRules
      resourceAccessRules: resourceAccessRules
      virtualNetworkRules:virtualNetworkRules
    }
    supportsHttpsTrafficOnly: true  
  }
}

resource roleAssignment_sa_tableContributorPrincipals 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = [for item in tableContributorPrincipals: {
  scope: StorageAccount
  name: guid('roleAssignment-sa-${item}')
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3')
    principalId: item
  }
}]

output storageAccountTableUrl string = StorageAccount.properties.primaryEndpoints.table
output storageID string = StorageAccount.id
