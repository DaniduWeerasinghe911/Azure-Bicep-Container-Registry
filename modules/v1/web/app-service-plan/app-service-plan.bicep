@description('Service plan name')
param appPlanName string

@description('Location for resources to be created')
param location string = resourceGroup().location

@allowed([
  'F1'
  'D1'
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1'
  'P2'
  'P3'
  'P4'
])
@description('App service app plan type')
param skuName string

@maxValue(10)
@description('Number of instances needed for the app service plan')
param skuCapacity int

@allowed([
  'windows'
  'linux'
])
@description('Hosting OS for the web application')
param appKind string

@description('Object containing diagnostics settings. If not provided diagnostics will not be set.')
param diagSettings object = {}

@description('Enable a Can Not Delete Resource Lock. Useful for production workloads.')
param enableResourceLock bool = false

@description('Object containing resource tags.')
param tags object = {}

var appServicePlanName = toLower('${appPlanName}-asp')

resource appServicePlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: appServicePlanName
  tags: !empty(tags) ? tags : null
  kind: ((appKind == 'windows') ? 'app' : 'linux')
  location: location
  sku: {
    name: skuName
    capacity: skuCapacity 
  }
  properties: {
    reserved: ((appKind == 'windows') ? false : true)
  }
}

resource diagnostics 'Microsoft.Insights/diagnosticsettings@2021-05-01-preview' = if (!empty(diagSettings)) {
  name: empty(diagSettings) ? 'dummy-value' : diagSettings.name
  scope: appServicePlan
  properties: {
    workspaceId: empty(diagSettings.workspaceId) ? json('null') : diagSettings.workspaceId
    storageAccountId: empty(diagSettings.storageAccountId) ? json('null') : diagSettings.storageAccountId
    eventHubAuthorizationRuleId: empty(diagSettings.eventHubAuthorizationRuleId) ? json('null') : diagSettings.eventHubAuthorizationRuleId 
    eventHubName: empty(diagSettings.eventHubName) ? json('null') : diagSettings.eventHubName
    
    logs: [
      {
        category: 'Audit'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }    
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: diagSettings.enableMetrics
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
    ]
  }
  dependsOn: [
    appServicePlan
  ]
}

// Resource Lock
resource deleteLock 'Microsoft.Authorization/locks@2016-09-01' = if (enableResourceLock) {
  name: '${appServicePlanName}-delete-lock'
  scope: appServicePlan
  properties: {
    level: 'CanNotDelete'
    notes: 'Enabled as part of IaC Deployment'
  }
  dependsOn: [
    appServicePlan
  ]
}

output name string = appServicePlan.name
output appServiceID string = appServicePlan.id
