// Deploys an Azure Front Door - please review the sample parameters file for examples on the object schema types needed

@description('The name of the frontdoor resource.')
param frontDoorName string

@description('Session Affinity configuration of the default Frontend Endpoint. Generally set to Disabled.')
param defaultFrontendSessionAffinity string = 'Disabled'

@description('Array of objects defining the custom frontend endpoints')
param customFrontendEndpoints array

@description('Array of objects defining the load balancing settings')
param loadBalancingSettings array

@description('Array of objects defining the health probe settings')
param healthProbeSettings array

@description('Array of objects defining the backend pools')
param backendPools array

@description('Array of objects defining the forwarding routing rules')
param forwardingRoutingRules array

@description('Array of objects defining the redirect routing rules')
param redirectRoutingRules array

@description('Object containing tags. If not provided tags will not be set/updated.')
param tags object = {}

@description('Object containing diagnostics settings. If not provided diagnostics will not be set.')
param diagSettings object = {}

@description('Enable a Can Not Delete Resource Lock.  Useful for production workloads.')
param enableResourceLock bool = false

// A default Frontend Endpoint is always generated
var defaultFrontendEndpoint = [
  {
    name: 'default'
    properties: {
      hostName: '${frontDoorName}.azurefd.net'
      sessionAffinityEnabledState: defaultFrontendSessionAffinity
    }
  }
]

var varFrontendEndpoints = union(defaultFrontendEndpoint, customFrontendEndpoints)

// Process the BackendPools to generate the resource IDs
var varBackendPools = [for backendPool in backendPools: {
  name: backendPool.name
  properties: {
    backends: backendPool.properties.backends
    loadBalancingSettings: {
      id: resourceId('Microsoft.Network/frontDoors/loadBalancingSettings', frontDoorName, backendPool.properties.loadBalancingSettings)
    }
    healthProbeSettings: {
      id: resourceId('Microsoft.Network/frontDoors/healthProbeSettings', frontDoorName, backendPool.properties.healthProbeSettings)
    }
  }
}]

// Process Routing Rules and resource IDs.  Note that Forwarding and Redirect have different RouteConfiguration properties. Hence need to split.
var varForwardingRoutingRules = [for fwdRoutingRule in forwardingRoutingRules: {
  name: fwdRoutingRule.name
  properties: {
    frontendEndpoints: [
      {
        id: resourceId('Microsoft.Network/frontDoors/frontEndEndpoints', frontDoorName, fwdRoutingRule.properties.frontendEndpointName)
      }
    ]
    acceptedProtocols: fwdRoutingRule.properties.acceptedProtocols
    patternsToMatch: fwdRoutingRule.properties.patternsToMatch
    routeConfiguration: {
      '@odata.type': '#Microsoft.Azure.FrontDoor.Models.FrontdoorForwardingConfiguration'
      forwardingProtocol: fwdRoutingRule.properties.routeConfiguration.forwardingProtocol
      cacheConfiguration: empty(fwdRoutingRule.properties.routeConfiguration.cacheConfiguration) ? json('null') : fwdRoutingRule.properties.routeConfiguration.cacheConfiguration
      customForwardingPath: empty(fwdRoutingRule.properties.routeConfiguration.customForwardingPath) ? json('null') : fwdRoutingRule.properties.routeConfiguration.customForwardingPath
      backendPool: {
        id: resourceId('Microsoft.Network/frontDoors/backEndPools', frontDoorName, fwdRoutingRule.properties.routeConfiguration.backendPool)
      }
    }
    enabledState: fwdRoutingRule.properties.enabledState
  }  
}]

var varRedirectRoutingRules = [for routingRule in redirectRoutingRules: {
  name: routingRule.name
  properties: {
    frontendEndpoints: [
      {
        id: resourceId('Microsoft.Network/frontDoors/frontEndEndpoints', frontDoorName, routingRule.properties.frontendEndpointName)
      }
    ]
    acceptedProtocols: routingRule.properties.acceptedProtocols
    patternsToMatch: routingRule.properties.patternsToMatch
    routeConfiguration: {
      '@odata.type': '#Microsoft.Azure.FrontDoor.Models.FrontdoorRedirectionConfiguration'
      redirectProtocol: routingRule.properties.routeConfiguration.forwardingProtocol
      redirectType: routingRule.properties.routeConfiguration.redirectType
      backendPool: {
        id: resourceId('Microsoft.Network/frontDoors/backEndPools', frontDoorName, routingRule.properties.routeConfiguration.backendPool)
      }
    }
    enabledState: routingRule.properties.enabledState
  }  
}]

// Routing Rules is a merge of both Forwarding and Redirect Rules
var varRoutingRules = union(varRedirectRoutingRules, varForwardingRoutingRules)

// Front Door Resource
resource frontDoor 'Microsoft.Network/frontDoors@2020-05-01' = {
  name: frontDoorName
  location: 'global'
  tags: !empty(tags) ? tags : json('null')
  properties: {
    enabledState: 'Enabled'
    frontendEndpoints: varFrontendEndpoints
    loadBalancingSettings: loadBalancingSettings
    healthProbeSettings: healthProbeSettings
    backendPools: varBackendPools
    routingRules: varRoutingRules
  }
}

// Diagnostics
resource diagnostics 'Microsoft.insights/diagnosticsettings@2017-05-01-preview' = if (!empty(diagSettings)) {
  name: diagSettings.name
  scope: frontDoor
  properties: {
    workspaceId: empty(diagSettings.workspaceId) ? json('null') : diagSettings.workspaceId
    storageAccountId: empty(diagSettings.storageAccountId) ? json('null') : diagSettings.storageAccountId
    eventHubAuthorizationRuleId: empty(diagSettings.eventHubAuthorizationRuleId) ? json('null') : diagSettings.eventHubAuthorizationRuleId
    eventHubName: empty(diagSettings.eventHubName) ? json('null') : diagSettings.eventHubName
    
    logs: [
      {
        category: 'FrontdoorAccessLog'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'FrontdoorWebApplicationFirewallLog'
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
  name: '${frontDoorName}-delete-lock'
  scope: frontDoor
  properties: {
    level: 'CanNotDelete'
    notes: 'Enabled as part of IaC Deployment'
  }
}
