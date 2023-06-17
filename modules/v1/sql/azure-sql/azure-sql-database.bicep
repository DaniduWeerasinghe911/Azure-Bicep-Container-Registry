@description('Name of existing Azure SQL Server')
param sqlServerName string

@description('Name of Database to create')
param databaseName string

@description('Location of resource')
param location string = resourceGroup().location

@description('A predefined set of SkuTypes. Currently template not configured to support Hyper-Scale or Business Critical.')
@allowed([
  'Basic'
  'Standard'
  'Premium'
  'vCoreGen5'
  'vCoreGen5Serverless'
])
param skuType string

@description('If DTU model, define amount of DTU. If vCore model, define number of vCores (max for serverless)')
param skuCapacity int

@description('Min vCore allocation. Applicable for vCore Serverless model only. Feed as string to handle floats.')
param skuMinCapacity string = '0.5'

@description('Maximum database size in bytes for allocation.')
param maxDbSize int

@description('Minutes before Auto Pause. Applicable for vCore Serverless model only')
param autoPauseDelay int = 60

@description('Defines the short term retention period.  Maximum of 35 days.')
param retentionPeriod int = 35

@description('The SQL database Collation.')
param databaseCollation string = 'SQL_Latin1_General_CP1_CI_AS'

@description('Whether the databases are zone redundant. Only supported in some regions.')
param zoneRedundant bool = false

@description('For Azure Hybrid Benefit, use BasePrice')
@allowed([
  'BasePrice'
  'LicenseIncluded'
])
param licenseType string = 'LicenseIncluded'

@description('Allow ReadOnly from secondary endpoints')
param readScaleOut string = 'Disabled'

@description('Set location of backups, geo, local or zone')
param requestedBackupStorageRedundancy string = 'Geo'

@description('Object containing resource tags.')
param tags object = {}

@description('Enable a Can Not Delete Resource Lock.  Useful for production workloads.')
param enableResourceLock bool = false

@description('Object containing diagnostics settings. If not provided diagnostics will not be set.')
param diagSettings object = {}

// Object map to help set SKU properties for database
var skuMap = {
  vCoreGen5: {
    name: 'GP_S_Gen5'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    kind: 'v12.0,user,vcore'
  }
  vCoreGen5Serverless: {
    name: 'GP_S_Gen5'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    kind: 'v12.0,user,vcore,serverless'
  }
  Basic: {
    name: 'Basic'
    tier: 'Basic'
    family: json('null')
    kind: 'v12.0,user'
  }
  Standard: {
    name: 'Standard'
    tier: 'Standard'
    family: json('null')
    kind: 'v12.0,user'
  }
  Premium: {
    name: 'Premium'
    tier: 'Premium'
    family: json('null')
    kind: 'v12.0,user'
  }
}

// Existing Azure SQL Server
resource sqlServer 'Microsoft.Sql/servers@2019-06-01-preview' existing = {
  name: sqlServerName
 }

 // Resource Definition
resource sqlDatabase 'Microsoft.Sql/servers/databases@2021-02-01-preview' = {
  parent: sqlServer
  name: databaseName
  location: location
  tags: !empty(tags) ? tags : json('null')
  sku: {
    name: skuMap[skuType].name
    tier: skuMap[skuType].tier
    family: skuMap[skuType].family
    capacity: skuCapacity
  }
  properties: {
    collation: databaseCollation
    maxSizeBytes: maxDbSize
    zoneRedundant: zoneRedundant
    licenseType: licenseType
    readScale: readScaleOut
    minCapacity: skuType == 'vCoreGen5Serverless' ? any(skuMinCapacity) : json('null')
    autoPauseDelay:  skuType == 'vCoreGen5Serverless' ? autoPauseDelay : json('null')
    requestedBackupStorageRedundancy: requestedBackupStorageRedundancy
  }
}

// Short Term Retention Policy
resource retention 'Microsoft.Sql/servers/databases/backupShortTermRetentionPolicies@2021-02-01-preview' = {
  parent: sqlDatabase
  name: 'default'
  properties: {
    retentionDays: retentionPeriod
  }
}

// Diagnostics
resource diagnostics 'Microsoft.insights/diagnosticsettings@2017-05-01-preview' = if (!empty(diagSettings)) {
  name: empty(diagSettings) ? 'dummy-value' : diagSettings.name
  scope: sqlDatabase
  properties: {
    workspaceId: empty(diagSettings.workspaceId) ? json('null') : diagSettings.workspaceId
    storageAccountId: empty(diagSettings.storageAccountId) ? json('null') : diagSettings.storageAccountId
    eventHubAuthorizationRuleId: empty(diagSettings.eventHubAuthorizationRuleId) ? json('null') : diagSettings.eventHubAuthorizationRuleId
    eventHubName: empty(diagSettings.eventHubName) ? json('null') : diagSettings.eventHubName
    
    logs: [
      {
        category: 'SQLInsights'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'AutomaticTuning'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'QueryStoreRuntimeStatistics'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'QueryStoreWaitStatistics'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'Errors'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'DatabaseWaitStatistics'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'Timeouts'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'Blocks'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'Deadlocks'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
    ]

    metrics: [
      {
        category: 'Basic'
        enabled: diagSettings.enableMetrics
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'InstanceAndAppAdvanced'
        enabled: diagSettings.enableMetrics
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'WorkloadManagement'
        enabled: diagSettings.enableMetrics
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }            
    ]
  }
}

// Resource Lock
resource deleteLock 'Microsoft.Authorization/locks@2016-09-01' = if (enableResourceLock) {
  name: '${databaseName}-delete-lock'
  scope: sqlDatabase
  properties: {
    level: 'CanNotDelete'
    notes: 'Enabled as part of IaC Deployment'
  }
}

// Output Resource Name and Resource Id as a standard to allow module referencing.
output name string = sqlDatabase.name
output id string = sqlDatabase.id
