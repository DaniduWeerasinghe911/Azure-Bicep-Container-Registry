@description('Function Premium Plan Name')
param fncPlanName string

@description('Location for resources to be created')
param location string = resourceGroup().location

@allowed([
  'EP1'
  'EP2'
  'EP3'
])
@description('Function Premium Plan')
param skuName string

@description('Object containing diagnostics settings. If not provided diagnostics will not be set.')
param diagSettings object = {}

@description('Enable a Can Not Delete Resource Lock. Useful for production workloads.')
param enableResourceLock bool

@description('Object containing resource tags.')
param tags object = {}

// Resource Definition
resource serverFarm 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: fncPlanName
  tags: !empty(tags) ? tags : null
  location: location
  sku: {
    name: skuName
    tier: 'ElasticPremium'
  }
  kind: 'elastic'
}

// Diagnostics
resource diagnostics 'Microsoft.insights/diagnosticsettings@2017-05-01-preview' = if (!empty(diagSettings)) {
  name: empty(diagSettings) ? 'dummy-value' : diagSettings.name
  scope: serverFarm
  properties: {
    workspaceId: empty(diagSettings.workspaceId) ? json('null') : diagSettings.workspaceId
    storageAccountId: empty(diagSettings.storageAccountId) ? json('null') : diagSettings.storageAccountId
    eventHubAuthorizationRuleId: empty(diagSettings.eventHubAuthorizationRuleId) ? json('null') : diagSettings.eventHubAuthorizationRuleId
    eventHubName: empty(diagSettings.eventHubName) ? json('null') : diagSettings.eventHubName
    
    metrics: [
      {
        category: 'AllMetrics'
        enabled: diagSettings.enableMetrics
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
    ]
  }
}

// Resource Lock
resource deleteLock 'Microsoft.Authorization/locks@2016-09-01' = if (enableResourceLock) {
  name: '${fncPlanName}-delete-lock'
  scope: serverFarm
  properties: {
    level: 'CanNotDelete'
    notes: 'Enabled as part of IaC Deployment'
  }
}

// Output Resource Name and Resource Id as a standard to allow module referencing.
output name string = serverFarm.name
output id string = serverFarm.id
