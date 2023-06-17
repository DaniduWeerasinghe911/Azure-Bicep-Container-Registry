@description('AVD Host Location')
param location string = 'eastUS'

@description('Host Pool Friendly Name')
param hostPoolFriendlyName string 

@description('Host Pool Type')
param hostPoolType string = 'Pooled'

@description('Location for all standard resources to be deployed into.')
param loadBalancerType string = 'BreadthFirst'

@description('Location for all standard resources to be deployed into.')
param preferredAppGroupType string = 'desktop'

@description('Location for all standard resources to be deployed into.')
param worksSpacefriendlyName string 

param expirationTime string = '2021-12-18T05:06:44.702Z'

@description('Maximu Sessions allowed per VM Host')
param maxSessionLimit int = 5

param diagSettings object

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2022-04-01-preview' = {
  name: hostPoolFriendlyName
  location: location
  properties: {
    friendlyName: hostPoolFriendlyName
    hostPoolType: hostPoolType
    loadBalancerType: loadBalancerType
    preferredAppGroupType: preferredAppGroupType
    registrationInfo: {
      expirationTime: expirationTime
      token: null
      registrationTokenOperation: 'Update' 
    }
    maxSessionLimit: maxSessionLimit
    startVMOnConnect: true
  }
}

/*
resource workSpace 'Microsoft.DesktopVirtualization/workspaces@2019-12-10-preview' = {
  name: worksSpacefriendlyName
  location: location
  properties: {
    friendlyName: worksSpacefriendlyName
    applicationGroupReferences:[
      applicationGroup.id
    ]
  }
}*/

resource applicationGroup 'Microsoft.DesktopVirtualization/applicationgroups@2019-12-10-preview' = {
  name: 'desktop-appgroup'
  location: location
  properties: {
    friendlyName: 'desktop-appgroup'
    applicationGroupType: 'Desktop'
    hostPoolArmPath: '${resourceGroup().id}/providers/Microsoft.DesktopVirtualization/hostPools/${hostPoolFriendlyName}'
  }
  dependsOn: [
    hostPool
  ]
}



//Diagnostics for HostPool
resource diagnostics 'Microsoft.Insights/diagnosticsettings@2021-05-01-preview' = if (!empty(diagSettings)) {
  name: empty(diagSettings) ? 'dummy-value' : diagSettings.name
  scope: hostPool
  properties: {
    workspaceId: empty(diagSettings.workspaceId) ? json('null') : diagSettings.workspaceId
    storageAccountId: empty(diagSettings.storageAccountId) ? json('null') : diagSettings.storageAccountId
    eventHubAuthorizationRuleId: empty(diagSettings.eventHubAuthorizationRuleId) ? json('null') : diagSettings.eventHubAuthorizationRuleId 
    eventHubName: empty(diagSettings.eventHubName) ? json('null') : diagSettings.eventHubName
    logs: [
      {
        category: 'Checkpoint'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'Error'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }    
      {
        category: 'Management'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }    
      {
        category: 'Connection'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }    
      {
        category: 'HostRegistration'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }    
      {
        category: 'AgentHealthStatus'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }    
    ]
  }
}
/*/Diagnostics for Workspace
resource workspaceDiagnostics 'Microsoft.Insights/diagnosticsettings@2021-05-01-preview' = if (!empty(diagSettings)) {
  name: empty(diagSettings) ? 'dummy-value' : diagSettings.name
  scope: workSpace
  properties: {
    workspaceId: empty(diagSettings.workspaceId) ? json('null') : diagSettings.workspaceId
    storageAccountId: empty(diagSettings.storageAccountId) ? json('null') : diagSettings.storageAccountId
    eventHubAuthorizationRuleId: empty(diagSettings.eventHubAuthorizationRuleId) ? json('null') : diagSettings.eventHubAuthorizationRuleId 
    eventHubName: empty(diagSettings.eventHubName) ? json('null') : diagSettings.eventHubName
    logs: [
      {
        category: 'Checkpoint'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'Error'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }    
      {
        category: 'Management'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }    
      {
        category: 'Feed'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }     
    ]
  }
}
*/

output hostPoolId string = hostPool.id

