// Bicep template to deploy an Application Service Environment

@description('Location of the resource.')
param location string = resourceGroup().location

@description('The name of the resource.')
param aseName string

@description('Internal Load Balancing Mode - None turns it off (for public ASE), Web,Publishing allows content to be uploaded as well as served from the ASE')
@allowed([
  'None'
  'Publishing'
  'Web'
  'Web, Publishing'
])
param internalLoadBalancingMode string = 'Web, Publishing'

@description('The version of the ASE to deploy (ASEV2 or ASEV3)')
@allowed([
  'ASEV2'
  'ASEV3'
])
param kind string

@description('The VNet ID to create the ASE in')
param virtualNetwork string

@description('The subnet name to create the ASE in')
param subnetName string

@description('Enable a Can Not Delete Resource Lock.  Useful for production workloads.')
param enableResourceLock bool = false

@description('Object containing diagnostics settings. If not provided diagnostics will not be set.')
param diagSettings object = {}

// Resource Definition
resource hostingEnvironment 'Microsoft.Web/hostingEnvironments@2020-12-01' = {
  name: aseName
  location: location
  kind: kind
  properties: {
    ipsslAddressCount: 0
    internalLoadBalancingMode: internalLoadBalancingMode
    virtualNetwork: {
      id: virtualNetwork
      subnet: subnetName
    }
  }
}

// Diagnostics
resource diagnostics 'Microsoft.insights/diagnosticsettings@2017-05-01-preview' = if (!empty(diagSettings)) {
  name: empty(diagSettings) ? 'dummy-value' : diagSettings.name
  scope: hostingEnvironment
  properties: {
    workspaceId: empty(diagSettings.workspaceId) ? json('null') : diagSettings.workspaceId
    storageAccountId: empty(diagSettings.storageAccountId) ? json('null') : diagSettings.storageAccountId
    eventHubAuthorizationRuleId: empty(diagSettings.eventHubAuthorizationRuleId) ? json('null') : diagSettings.eventHubAuthorizationRuleId
    eventHubName: empty(diagSettings.eventHubName) ? json('null') : diagSettings.eventHubName
    
    logs: [
      {
        category: 'AppServiceEnvironmentPlatformLogs'
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

// Resource Lock
resource deleteLock 'Microsoft.Authorization/locks@2016-09-01' = if (enableResourceLock) {
  name: '${aseName}-delete-lock'
  scope: hostingEnvironment
  properties: {
    level: 'CanNotDelete'
    notes: 'Enabled as part of IaC Deployment'
  }
}

// Output Hosting ID and name as a standard to allow module referencing.
output hostingEnvironmentId string = hostingEnvironment.id
output hostingName string = hostingEnvironment.name
