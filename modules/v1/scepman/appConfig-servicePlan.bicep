@description('Provide the AppServicePlan ID of an existing App Service Plan. Keep default value \'none\' if you want to create a new one.')
param existingAppServicePlanID string = 'none'

@description('Name of the App Service Plan to be created')
param AppServicePlanName string

@description('Name of App Service to be created')
param appServiceName string

@description('Name of second App Service to be created')
param appServiceName2 string

@description('Resource Group')
param location string

@description('Object containing diagnostics settings. If not provided diagnostics will not be set.')
@metadata({
  name: 'Diagnostic settings name'
  workspaceId: 'Log analytics resource id'
  storageAccountId: 'Storage account resource id'
  eventHubAuthorizationRuleId: 'EventHub authorization rule id'
  eventHubName: 'EventHub name'
  enableLogs: 'Enable logs'
  enableMetrics: 'Enable metrics'
  retentionPolicy: {
    days: 'Number of days to keep data'
    enabled: 'Enable retention policy'
  }
})
param diagSettings object = {}


resource AppServicePlanName_resource 'Microsoft.Web/serverfarms@2021-02-01' = if (existingAppServicePlanID == 'none') {
  name: AppServicePlanName
  location: location
  sku: {
    tier: 'Standard'
    name: 'S1'
  }
}

resource appServiceName_resource 'Microsoft.Web/sites@2021-02-01' = {
  name: appServiceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: ((existingAppServicePlanID == 'none') ? AppServicePlanName_resource.id : existingAppServicePlanID)
    clientAffinityEnabled: false

  }
}

resource appServiceName2_resource 'Microsoft.Web/sites@2021-02-01' = {
  name: appServiceName2
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: ((existingAppServicePlanID == 'none') ? AppServicePlanName_resource.id : existingAppServicePlanID)
    httpsOnly: true
    clientAffinityEnabled: true
  }
}

resource diagnostics 'Microsoft.Insights/diagnosticsettings@2021-05-01-preview' = if (!empty(diagSettings)) {
  name: empty(diagSettings) ? 'dummy-value' : diagSettings.name
  scope: AppServicePlanName_resource
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

output scepmanURL string = uri('https://${appServiceName_resource.properties.defaultHostName}', '/')
output scepmanPrincipalID string = reference(appServiceName, '2021-02-01', 'Full').identity.principalId
output certmasterPrincipalID string = reference(appServiceName2, '2021-02-01', 'Full').identity.principalId
output appServicePlanID string = ((existingAppServicePlanID == 'none') ? AppServicePlanName_resource.id : existingAppServicePlanID)
