@description('AVD Workspace Name')
param avdworkspacename string

@description('Location for the Workspace')
param location string = 'eastus'

@description('Application Group Reference')
param appgroupref array = []

@description('Application Group Reference')
param diagSettings object

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2021-07-12' = {
  name: avdworkspacename
  location: location
  properties: {
    applicationGroupReferences:appgroupref
    description: 'AVD Workspace'
    friendlyName: avdworkspacename
  }
}


resource workspaceDiagnostics 'Microsoft.Insights/diagnosticsettings@2021-05-01-preview' = if (!empty(diagSettings)) {
  name: empty(diagSettings) ? 'dummy-value' : diagSettings.name
  scope: workspace
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

output workspaceid string = workspace.id

