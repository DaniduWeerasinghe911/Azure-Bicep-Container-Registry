// Bicep template to deploy a Service Bus Namespace

@description('Location of the resource.')
param location string = resourceGroup().location

@description('The name of the Service Bus Namespace to be created')
param sbNamespaceName string

@description('Type of Namespace to deploy')
@allowed([
  'Basic'
  'Premium'
  'Standard'
])
param nsSku string = 'Standard'

@description('Add Zone Redundancy to the Namespace deployment')
@allowed([
  true
  false
])
param zoneRedundant bool = false

@description('Object containing diagnostics settings. If not provided diagnostics will not be set.')
param diagSettings object = {}

// Resources
resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-01-01-preview' = {
  name: sbNamespaceName
  location: location
  sku: {
    name: nsSku
    tier: nsSku
  }
  properties: {
    zoneRedundant: zoneRedundant
  }
}

// Diagnostics
resource diagnostics 'Microsoft.insights/diagnosticsettings@2017-05-01-preview' = if (!empty(diagSettings)) {
  name: empty(diagSettings) ? 'dummy-value' : diagSettings.name
  scope: serviceBusNamespace
  properties: {
    workspaceId: empty(diagSettings.workspaceId) ? json('null') : diagSettings.workspaceId
    storageAccountId: empty(diagSettings.storageAccountId) ? json('null') : diagSettings.storageAccountId
    eventHubAuthorizationRuleId: empty(diagSettings.eventHubAuthorizationRuleId) ? json('null') : diagSettings.eventHubAuthorizationRuleId
    eventHubName: empty(diagSettings.eventHubName) ? json('null') : diagSettings.eventHubName
    
    logs: [
      {
        category: 'OperationalLogs'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'VNetAndIPFilteringLogs'
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
}

// Output Resource Name and Resource Id as a standard to allow module referencing.
output name string = serviceBusNamespace.name
output id string = serviceBusNamespace.id
