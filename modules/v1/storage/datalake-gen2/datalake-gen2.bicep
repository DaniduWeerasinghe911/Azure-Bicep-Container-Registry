// Storage Account for Datalake Gen2

@description('The name of the resource.')
param storageAccountName string

@description('Location of the resource.')
param location string = resourceGroup().location

@description('Defines Performance and Redundancy type. Note that Premium only supports BlockBlobs.')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
param accountType string

@description('Allow the use of SAS Keys to access storage account')
param allowSharedKeyAccess bool = true

@description('Enable NFSv3 protocol support')
param enableNFSv3 bool = false

@description('Storage account access tier, Hot for frequently accessed data or Cool for infreqently accessed data')
@allowed([
  'Hot'
  'Cool'
])
param storageTier string = 'Hot'

@description('Enable/Disable soft delete Data Protection features')
param enableDataProtection bool = true

@description('Amount of days the soft deleted blob data is stored and available for recovery')
@minValue(1)
@maxValue(365)
param blobDeleteRetentionDays int = 30

@description('Amount of days the soft deleted container is stored and available for recovery')
@minValue(1)
@maxValue(365)
param containerDeleteRetentionDays int = 30

@description('Amount of days the soft deleted File Share is stored and available for recovery')
@minValue(1)
@maxValue(365)
param shareDeleteRetentionDays int = 30

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

@description('Object containing resource tags.')
param tags object = {}

@description('Enable a Can Not Delete Resource Lock.  Useful for production workloads.')
param enableResourceLock bool = false

@description('Object containing diagnostics settings. If not provided diagnostics will not be set.')
param diagSettings object = {}

// Premium Account type requires BlockBlobStorage config
var kind = (accountType == 'Premium_LRS' || accountType == 'Premium_ZRS') ? 'BlockBlobStorage' : 'StorageV2'

// Resource Definition
resource storage 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storageAccountName
  location: location
  tags: !empty(tags) ? tags : json('null')
  properties: {
    minimumTlsVersion: 'TLS1_2'       // Security Reasons
    supportsHttpsTrafficOnly: true    // Security Reasons
    allowBlobPublicAccess: false      // Security Reasons
    allowSharedKeyAccess: allowSharedKeyAccess  
    accessTier: storageTier
    networkAcls: {
      bypass: networkAclsBypass
      defaultAction: networkAclsDefaultAction
      ipRules: ipRules
      resourceAccessRules: resourceAccessRules
      virtualNetworkRules: virtualNetworkRules
    }
    isHnsEnabled: true   // Required for Datalake
    isNfsV3Enabled: enableNFSv3  
  }
  sku: {
    name: accountType
  }
  kind: kind
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2021-04-01' = {
  parent: storage
  name: 'default'
  properties: {
    containerDeleteRetentionPolicy: {
      enabled: enableDataProtection
      days: containerDeleteRetentionDays
    }    
  }
}

// Only applicable for General Purpose Storage Accounts (not premium block blobs)
resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2021-04-01' = if(kind == 'StorageV2') {
  parent: storage
  name: 'default'
  properties: {
    shareDeleteRetentionPolicy: {
      enabled: enableDataProtection
      days: shareDeleteRetentionDays
    }
  }
}

// Resource Lock
resource deleteLock 'Microsoft.Authorization/locks@2016-09-01' = if (enableResourceLock) {
  name: '${storageAccountName}-delete-lock'
  scope: storage
  properties: {
    level: 'CanNotDelete'
    notes: 'Enabled as part of IaC Deployment'
  }
}

// Storage Resource Diagnostics
resource root_diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(diagSettings)) {
  name: empty(diagSettings) ? 'dummy-value' : diagSettings.name
  scope: storage
  properties: {
    workspaceId: empty(diagSettings.workspaceId) ? json('null') : diagSettings.workspaceId
    storageAccountId: empty(diagSettings.storageAccountId) ? json('null') : diagSettings.storageAccountId
    eventHubAuthorizationRuleId: empty(diagSettings.eventHubAuthorizationRuleId) ? json('null') : diagSettings.eventHubAuthorizationRuleId
    eventHubName: empty(diagSettings.eventHubName) ? json('null') : diagSettings.eventHubName

    metrics: [
      {
        category: 'Transaction'
        enabled: diagSettings.enableMetrics
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
    ]
  }
}

resource blob_diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(diagSettings)) {
  name: empty(diagSettings) ? 'dummy-value' : diagSettings.name
  scope: blobServices
  properties: {
    workspaceId: empty(diagSettings.workspaceId) ? json('null') : diagSettings.workspaceId
    storageAccountId: empty(diagSettings.storageAccountId) ? json('null') : diagSettings.storageAccountId
    eventHubAuthorizationRuleId: empty(diagSettings.eventHubAuthorizationRuleId) ? json('null') : diagSettings.eventHubAuthorizationRuleId
    eventHubName: empty(diagSettings.eventHubName) ? json('null') : diagSettings.eventHubName

    logs: [
      {
        category: 'StorageRead'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'StorageWrite'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'StorageDelete'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
    ]
  }
}

// Only applicable for General Purpose Storage Accounts (not premium block blobs)
resource file_diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(diagSettings) && kind == 'StorageV2') {
  name: empty(diagSettings) ? 'dummy-value' : diagSettings.name
  scope: fileServices
  properties: {
    workspaceId: empty(diagSettings.workspaceId) ? json('null') : diagSettings.workspaceId
    storageAccountId: empty(diagSettings.storageAccountId) ? json('null') : diagSettings.storageAccountId
    eventHubAuthorizationRuleId: empty(diagSettings.eventHubAuthorizationRuleId) ? json('null') : diagSettings.eventHubAuthorizationRuleId
    eventHubName: empty(diagSettings.eventHubName) ? json('null') : diagSettings.eventHubName

    logs: [
      {
        category: 'StorageRead'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'StorageWrite'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'StorageDelete'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
    ]
  }
}

// Output Resource Name and Resource Id as a standard to allow module referencing.
output name string = storage.name
output id string = storage.id
