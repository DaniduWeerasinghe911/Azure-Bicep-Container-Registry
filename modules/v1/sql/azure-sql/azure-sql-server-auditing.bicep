// Enables Auditing on Azure SQL Server.
// This is not captured in main Azure SQL Server Resource definition as it has non-standard configuration for diagnostic logs

@description('Name of existing Azure SQL Server')
param sqlServerName string

@description('Location of the resource.')
param location string = resourceGroup().location

@description('Object containing diagnostics settings.')
param diagSettings object = {}

@description('Specifies the Actions-Groups and Actions to audit. Default value should cover core scenarios.')
param auditActionsAndGroups array = [
  'BATCH_COMPLETED_GROUP'
  'SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP'
  'FAILED_DATABASE_AUTHENTICATION_GROUP'
]

// Get existing Azure SQL Resource Object
resource sqlServer 'Microsoft.Sql/servers@2019-06-01-preview' existing = {
  name: sqlServerName
}

// Need to define master database as a resource to enable server level security auditing
resource sqlServer_master_database 'Microsoft.Sql/servers/databases@2017-03-01-preview' = {
  parent: sqlServer
  location: location
  name: 'master'
  properties: {}
}

// SQL Server Auditing Config
resource auditSettings 'Microsoft.Sql/servers/auditingSettings@2017-03-01-preview' = {
  parent: sqlServer
  name: 'default'
  properties: {
    state: 'Enabled'
    auditActionsAndGroups: auditActionsAndGroups
    isAzureMonitorTargetEnabled: true
  }
}

// SQL Server Auditing to Log Analytics Workspace
resource diagnostics 'Microsoft.insights/diagnosticsettings@2017-05-01-preview' = {
  name: 'audit-log'
  scope: sqlServer_master_database
  properties: {
    workspaceId: empty(diagSettings.workspaceId) ? json('null') : diagSettings.workspaceId
    storageAccountId: empty(diagSettings.storageAccountId) ? json('null') : diagSettings.storageAccountId
    eventHubAuthorizationRuleId: empty(diagSettings.eventHubAuthorizationRuleId) ? json('null') : diagSettings.eventHubAuthorizationRuleId
    eventHubName: empty(diagSettings.eventHubName) ? json('null') : diagSettings.eventHubName
    
    logs: [
      {
        category: 'SQLSecurityAuditEvents'
        enabled: true
      }
    ]
  }
}



