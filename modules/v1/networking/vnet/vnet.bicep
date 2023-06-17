@description('The name of the Virtual Network')
param vnetName string

@description('Location for resources to be created')
param location string = resourceGroup().location

@description('The CIDR ranges for the Virtual Network')
param addressPrefixes array

@description('List of all subnet object definitions')
param subnets array

@description('Object containing DNS servers for the virtual network. Leave blank if using Azure DNS.')
@metadata({
  note: 'Sample Input'
  dhcpOptions: {
    dnsServers: [
      '10.0.6.4'
      '10.0.6.5'
      '10.1.2.3'
    ]
  }
})
param dhcpOptions object = {}

@description('Object containing resource tags.')
param tags object = {}

@description('Enable a Can Not Delete Resource Lock. Useful for production workloads.')
param enableResourceLock bool

@description('Object containing diagnostics settings. If not provided diagnostics will not be set.')
param diagSettings object = {}

// Resource Definition
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnetName
  location: location
  tags: !empty(tags) ? tags : json('null')
  properties: {
    dhcpOptions: empty(dhcpOptions) ? json('null') : dhcpOptions
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    subnets: [ for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        networkSecurityGroup: empty(subnet.networkSecurityGroup) ? json('null') : {
          id: subnet.networkSecurityGroup
        }
        routeTable: empty(subnet.routeTable) ? json('null') : {
          id: subnet.routeTable
        }
        privateEndpointNetworkPolicies: empty(subnet.privateEndpointNetworkPolicies) ? 'Enabled' : subnet.privateEndpointNetworkPolicies
        privateLinkServiceNetworkPolicies: empty(subnet.privateLinkServiceNetworkPolicies) ? 'Enabled' : subnet.privateLinkServiceNetworkPolicies
        serviceEndpoints: empty(subnet.serviceEndpoints) ? [] : subnet.serviceEndpoints
        serviceEndpointPolicies: empty(subnet.serviceEndpointPolicies) ? [] : subnet.serviceEndpointPolicies
        delegations:  empty(subnet.delegations) ? [] : subnet.delegations
      }
    }]
  }
}

// Diagnostics
resource diagnostics 'Microsoft.Insights/diagnosticsettings@2021-05-01-preview' = if (!empty(diagSettings)) {
  name: empty(diagSettings) ? 'dummy-value' : diagSettings.name
  scope: virtualNetwork
  properties: {
    workspaceId: empty(diagSettings.workspaceId) ? json('null') : diagSettings.workspaceId
    storageAccountId: empty(diagSettings.storageAccountId) ? json('null') : diagSettings.storageAccountId
    eventHubAuthorizationRuleId: empty(diagSettings.eventHubAuthorizationRuleId) ? json('null') : diagSettings.eventHubAuthorizationRuleId 
    eventHubName: empty(diagSettings.eventHubName) ? json('null') : diagSettings.eventHubName
    
    logs: [
      {
        category: 'VMProtectionAlerts'
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
  name: '${vnetName}-delete-lock'
  scope: virtualNetwork
  properties: {
    level: 'CanNotDelete'
    notes: 'Enabled as part of IaC Deployment'
  }
  dependsOn: [
    virtualNetwork
  ]
}


output name string = virtualNetwork.name
output id string = virtualNetwork.id
output subnets array = [for (subnet, i) in subnets: {
  name: virtualNetwork.properties.subnets[i].name
  id: virtualNetwork.properties.subnets[i].id
}]
