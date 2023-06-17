@description('Name of the Gateway')
param vnetGatewayName string

@description('Location for resources to be created')
param location string = resourceGroup().location

@description('The name of the Public IP address')
param publicIpNameVPN string

@description('The SKU of the Gateway')
param sku string

@allowed([
  'Vpn'
  'ExpressRoute'
])
@description('They type of gateway either Vpn or ExpressRoute')
param gatewayType string

@description('The Virtual Network name to connect the Gateway')
param vnetName string

@description('The resource group which hosts the Virtual Network')
param vnetResourceGroup string

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

param publicCertData string

param vpnIPRange string

@description('Enable a Can Not Delete Resource Lock. Useful for production workloads.')
param enableResourceLock bool = false

@description('Object containing resource tags.')
@metadata({
  tagKey: 'tag value'
})
param tags object = {}

resource publicIP 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: '${publicIpNameVPN}-001'
  location: location
  sku: {
    name: 'Standard'
  }
  tags: !empty(tags) ? tags : null
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource publicIPDiagnostics 'Microsoft.Insights/diagnosticsettings@2021-05-01-preview' = if (!empty(diagSettings)) {
  name: empty(diagSettings) ? 'dummy-value' : diagSettings.name
  scope: publicIP
  properties: {
    workspaceId: empty(diagSettings.workspaceId) ? json('null') : diagSettings.workspaceId
    storageAccountId: empty(diagSettings.storageAccountId) ? json('null') : diagSettings.storageAccountId
    eventHubAuthorizationRuleId: empty(diagSettings.eventHubAuthorizationRuleId) ? json('null') : diagSettings.eventHubAuthorizationRuleId
    eventHubName: empty(diagSettings.eventHubName) ? json('null') : diagSettings.eventHubName

    logs: [
      {
        category: 'DDoSProtectionNotifications'
        enabled: diagSettings.enableLogs
      }
      {
        category: 'DDoSMitigationFlowLogs'
        enabled: diagSettings.enableLogs
      }
      {
        category: 'DDoSMitigationReports'
        enabled: diagSettings.enableLogs
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

resource virtualNetworkGateway 'Microsoft.Network/virtualNetworkGateways@2020-11-01' = {
  name: vnetGatewayName
  location: location
  tags: !empty(tags) ? tags : null
  properties: {
    activeActive: false
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId(vnetResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnetName, 'GatewaySubnet')
          }
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
    sku: {
      name: sku
      tier: sku
    }
    gatewayType: gatewayType
    vpnType: 'RouteBased'
    vpnClientConfiguration: {
      vpnClientAddressPool: {
        addressPrefixes: [
          vpnIPRange
        ]
      }
      vpnClientProtocols: [
        'IkeV2'
        'SSTP'
      ]
      vpnAuthenticationTypes: [
        'Certificate'
      ]
      vpnClientRootCertificates: [
        {
          name: 'rootca1'
          properties: {
            publicCertData: publicCertData
          }
        }
      ]
      vpnClientRevokedCertificates: []
      radiusServers: []
      vpnClientIpsecPolicies: []
    }
  }
}

resource gatewayDiagnostics 'Microsoft.Insights/diagnosticsettings@2021-05-01-preview' = if (!empty(diagSettings)) {
  name: empty(diagSettings) ? 'dummy-value' : diagSettings.name
  scope: virtualNetworkGateway
  properties: {
    workspaceId: empty(diagSettings.workspaceId) ? json('null') : diagSettings.workspaceId
    storageAccountId: empty(diagSettings.storageAccountId) ? json('null') : diagSettings.storageAccountId
    eventHubAuthorizationRuleId: empty(diagSettings.eventHubAuthorizationRuleId) ? json('null') : diagSettings.eventHubAuthorizationRuleId
    eventHubName: empty(diagSettings.eventHubName) ? json('null') : diagSettings.eventHubName

    logs: [
      {
        category: 'GatewayDiagnosticLog'
        enabled: diagSettings.enableLogs
      }
      {
        category: 'TunnelDiagnosticLog'
        enabled: diagSettings.enableLogs
      }
      {
        category: 'RouteDiagnosticLog'
        enabled: diagSettings.enableLogs
      }
      {
        category: 'IKEDiagnosticLog'
        enabled: diagSettings.enableLogs
      }
      {
        category: 'P2SDiagnosticLog'
        enabled: diagSettings.enableLogs
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
  name: '${vnetGatewayName}-delete-lock'
  scope: virtualNetworkGateway
  properties: {
    level: 'CanNotDelete'
    notes: 'Enabled as part of IaC Deployment'
  }
}

output virtualNetworkGatewayID string = virtualNetworkGateway.id
