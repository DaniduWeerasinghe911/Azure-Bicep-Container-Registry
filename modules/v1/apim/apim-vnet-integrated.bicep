// Deploys APIM that is VNET Integrated

@description('Azure API Management Resource Name.')
param apimName string

@description('Location of the resource.')
param location string = resourceGroup().location

@description('Name of the Sku. VNET Integration only supported on Developer or Premium')
@allowed([
  'Developer'
  'Premium'
])
param skuName string

@description('Capacity of the SKU. For Consumption SKU capacity must be specified as 0.')
param skuCapacity int

@description('Internal or External VNET Integration')
@allowed([
  'Internal'
  'External'
])
param virtualNetworkType string

@description('Publisher Name')
param publisherName string

@description('Publisher Email')
param publisherEmail string

@description('Optional. List of Availability Zones to deploy to. Valid on in AZ regions.')
param availabilityZones array = []

@description('Resource Name of the Subnet to deploy into.')
param subnetName string

@description('Resource Name of the Vnet the Subnet to deploy into is in.')
param vnetName string

@description('Public IP address resource name.')
param publicIPAddressName string = '${apimName}-pip'

@description('Object containing resource tags.')
param tags object = {}

@description('Enable a Can Not Delete Resource Lock.  Useful for production workloads.')
param enableResourceLock bool = false

@description('Object containing diagnostics settings. If not provided diagnostics will not be set.')
param diagSettings object = {}

// Public IP Resource Definition
resource publicIp 'Microsoft.Network/publicIpAddresses@2019-02-01' = if (virtualNetworkType == 'External') {
  name: publicIPAddressName
  location: location
  tags: !empty(tags) ? tags : json('null')  
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// APIM Resource Definition
resource apim 'Microsoft.ApiManagement/service@2021-01-01-preview' = {
  name: apimName
  location: location
  tags: !empty(tags) ? tags : json('null')
  sku: {
    capacity: skuCapacity
    name: skuName
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicIpAddressId: virtualNetworkType == 'External' ? publicIp.id : json('null')
    virtualNetworkConfiguration: {
      subnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
    }
    publisherEmail: publisherEmail
    publisherName: publisherName
    virtualNetworkType: virtualNetworkType
  }
  zones: empty(availabilityZones) ? json('null') : availabilityZones

}

// APIM Resource Diagnostics
resource apim_diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(diagSettings)) {
  name: empty(diagSettings) ? 'dummy-value' : diagSettings.name
  scope: apim
  properties: {
    workspaceId: empty(diagSettings.workspaceId) ? json('null') : diagSettings.workspaceId
    storageAccountId: empty(diagSettings.storageAccountId) ? json('null') : diagSettings.storageAccountId
    eventHubAuthorizationRuleId: empty(diagSettings.eventHubAuthorizationRuleId) ? json('null') : diagSettings.eventHubAuthorizationRuleId
    eventHubName: empty(diagSettings.eventHubName) ? json('null') : diagSettings.eventHubName

    logs: [
      {
        category: 'GatewayLogs'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }   
      {
        category: 'WebSocketConnectionLogs'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }   
    ]
  }
}

// Public IP Address Resource Diagnostics
resource pip_diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(diagSettings)  && virtualNetworkType == 'External') {
  name: empty(diagSettings) ? 'dummy-value' : diagSettings.name
  scope: publicIp
  properties: {
    workspaceId: empty(diagSettings.workspaceId) ? json('null') : diagSettings.workspaceId
    storageAccountId: empty(diagSettings.storageAccountId) ? json('null') : diagSettings.storageAccountId
    eventHubAuthorizationRuleId: empty(diagSettings.eventHubAuthorizationRuleId) ? json('null') : diagSettings.eventHubAuthorizationRuleId
    eventHubName: empty(diagSettings.eventHubName) ? json('null') : diagSettings.eventHubName

    logs: [
      {
        category: 'DDoSProtectionNotifications'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }   
      {
        category: 'DDoSMitigationFlowLogs'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }   
      {
        category: 'DDoSMitigationReports'
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
resource apim_deleteLock 'Microsoft.Authorization/locks@2016-09-01' = if (enableResourceLock) {
  name: '${apimName}-delete-lock'
  scope: apim
  properties: {
    level: 'CanNotDelete'
    notes: 'Enabled as part of IaC Deployment'
  }
}
resource pip_deleteLock 'Microsoft.Authorization/locks@2016-09-01' = if (enableResourceLock && virtualNetworkType == 'External') {
  name: '${publicIPAddressName}-delete-lock'
  scope: publicIp
  properties: {
    level: 'CanNotDelete'
    notes: 'Enabled as part of IaC Deployment'
  }
}

// Output Resource Name and Resource Id as a standard to allow module referencing.
output name string = apim.name
output id string = apim.id
output privateIpAddresses array = apim.properties.privateIPAddresses
output publicIpAddresses array = virtualNetworkType == 'External' ? apim.properties.publicIPAddresses : []
output publicIpAddressId string = virtualNetworkType == 'External' ? apim.properties.publicIpAddressId : ''
