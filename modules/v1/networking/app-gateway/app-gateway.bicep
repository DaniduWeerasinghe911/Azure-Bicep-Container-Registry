@description('Location in which resources will be created')
param location string = resourceGroup().location

@description('The number of Azure Application Gateway capacity units to provision. This setting has a direct impact on consumption cost and is recommended to be left at the default value of 1')
param appGatewayCapacity int = 1

@description('Application Gateway name')
param appGatewayName string

@description('The name of the vnet the Application Gateway will be installed into')
param appGatewayVnetName string

param appGatewayVnetRg string

@description('The reosuce ID of the public IP the application gateway will use')
param appGatewayPublicIpId string

@description('Name of an application gateway SKU.')
@allowed([
  'Standard_Large'
  'Standard_Medium'
  'Standard_Small'
  'Standard_v2'
  'WAF_Large'
  'WAF_Medium'
  'WAF_v2'
])
param appGatewaySkuName string

@description('Tier of an application gateway.')
@allowed([
  'Standard'
  'Standard_v2'
  'WAF'
  'WAF_v2'
])
param appGatewaySkuTier string

param appGatewayBackendAddressPools array

param appGatewayBackendHttpSettingsCollection array =[]
param appGatewayHttpListeners array =[]
param appGatewayRequestRoutingRules array =[]
param appGatewayProbes array = []
param appGatewayUrlPathMaps array = []
param webApplicationFirewallConfiguration object = {}

@description('Object containing resource tags.')
param tags object = {}

@description('Enable a Can Not Delete Resource Lock.  Useful for production workloads.')
param enableResourceLock bool = false

@description('Object containing diagnostics settings. If not provided diagnostics will not be set.')
param diagSettings object = {}

resource appgateway 'Microsoft.Network/applicationGateways@2021-02-01' = {
  name: appGatewayName
  location: location
  tags: !empty(tags) ? tags : json('null')
  properties: {
    sku: {
      name: appGatewaySkuName
      tier: appGatewaySkuTier
      capacity: appGatewayCapacity
    }
    gatewayIPConfigurations: [
      {
        name: 'appGwIpConfig'
        properties: {
          subnet: {
            id: resourceId(appGatewayVnetRg, 'Microsoft.Network/virtualNetworks/subnets', appGatewayVnetName, 'AppGatewaySubnet')
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: appGatewayPublicIpId
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
      {
        name: 'port_443'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: appGatewayBackendAddressPools
    backendHttpSettingsCollection: appGatewayBackendHttpSettingsCollection
    httpListeners: appGatewayHttpListeners
    requestRoutingRules: appGatewayRequestRoutingRules
    urlPathMaps: appGatewayUrlPathMaps
    probes: appGatewayProbes
    webApplicationFirewallConfiguration: webApplicationFirewallConfiguration
  }
}

// App Gateway Resource Diagnostics
resource diagnostics 'Microsoft.insights/diagnosticsettings@2021-05-01-preview' = if (!empty(diagSettings)) {
  name: empty(diagSettings) ? 'dummy-value' : diagSettings.name
  scope: appgateway
  properties: {
    logAnalyticsDestinationType: 'Dedicated'
    workspaceId: empty(diagSettings.workspaceId) ? json('null') : diagSettings.workspaceId
    storageAccountId: empty(diagSettings.storageAccountId) ? json('null') : diagSettings.storageAccountId
    eventHubAuthorizationRuleId: empty(diagSettings.eventHubAuthorizationRuleId) ? json('null') : diagSettings.eventHubAuthorizationRuleId
    eventHubName: empty(diagSettings.eventHubName) ? json('null') : diagSettings.eventHubName

    logs: [
      {
        category: 'ApplicationGatewayAccessLog'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'ApplicationGatewayPerformanceLog'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'ApplicationGatewayPerformanceLog'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'ApplicationGatewayFirewallLog'
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
  name: '${appGatewayName}-delete-lock'
  scope: appgateway
  properties: {
    level: 'CanNotDelete'
    notes: 'Enabled as part of IaC Deployment'
  }
}
