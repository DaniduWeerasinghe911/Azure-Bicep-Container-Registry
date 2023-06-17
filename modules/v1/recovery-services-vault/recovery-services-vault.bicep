@description('Recovery Services vault name')
param vaultName string

@description('Location of Recovery Services vault')
param location string = resourceGroup().location

@description('Enable system identity for Recovery Services vault')
param enableSystemIdentity bool = false

@description('Enable system identity for Recovery Services vault')
@allowed([
  'Standard'
  'RS0'
])
param sku string = 'RS0'

@description('Storage replication type for Recovery Services vault')
@allowed([
  'LocallyRedundant'
  'GeoRedundant'
  'ReadAccessGeoZoneRedundant'
  'ZoneRedundant'
])
param storageType string = 'GeoRedundant'

@description('Enable cross region restore')
param enablecrossRegionRestore bool = false

@description('Array containing backup policies')
@metadata({
  policyName: 'Backup policy name'
  properties: 'Object containing backup policy settings'
})
param backupPolicies array = []

@metadata({
  tagKey: 'tag value'
})
@description('Object containing resource tags.')
param tags object = {}

@description('Enable a Can Not Delete Resource Lock.  Useful for production workloads.')
param enableResourceLock bool = false

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
@description('Object containing diagnostics settings. If not provided diagnostics will not be set.')
param diagSettings object = {}

resource vault 'Microsoft.RecoveryServices/vaults@2021-06-01' = {
  name: vaultName
  location: location
  tags: !empty(tags) ? tags : json('null')
  identity: {
    type: enableSystemIdentity ? 'SystemAssigned' : 'None'
  }
  properties: {}
  sku: {
    name: sku
    tier: 'Standard'
  }
}

resource backupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2021-06-01' = [for policy in backupPolicies: {
  parent: vault
  name: policy.policyName
  location: location
  properties: policy.properties
}]

resource vaultConfig 'Microsoft.RecoveryServices/vaults/backupstorageconfig@2021-04-01' = {
  name: '${vault.name}/VaultStorageConfig'
  properties: {
    crossRegionRestoreFlag: enablecrossRegionRestore
    storageType: storageType
  }
}

resource deleteLock 'Microsoft.Authorization/locks@2016-09-01' = if (enableResourceLock) {
  name: '${vaultName}-delete-lock'
  scope: vault
  properties: {
    level: 'CanNotDelete'
    notes: 'Enabled as part of IaC Deployment'
  }
}

resource diagnostics 'Microsoft.insights/diagnosticsettings@2017-05-01-preview' = if (!empty(diagSettings)) {
  name: empty(diagSettings) ? 'dummy-value' : diagSettings.name
  scope: vault
  properties: {
    workspaceId: empty(diagSettings.workspaceId) ? json('null') : diagSettings.workspaceId
    storageAccountId: empty(diagSettings.storageAccountId) ? json('null') : diagSettings.storageAccountId
    eventHubAuthorizationRuleId: empty(diagSettings.eventHubAuthorizationRuleId) ? json('null') : diagSettings.eventHubAuthorizationRuleId
    eventHubName: empty(diagSettings.eventHubName) ? json('null') : diagSettings.eventHubName

    logs: [
      {
        category: 'AzureBackupReport'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'AzureSiteRecoveryJobs'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'AzureSiteRecoveryEvents'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'AzureSiteRecoveryReplicatedItems'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'AzureSiteRecoveryReplicationStats'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'AzureSiteRecoveryRecoveryPoints'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'AzureSiteRecoveryReplicationDataUploadRate'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'AzureSiteRecoveryProtectedDiskDataChurn'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'CoreAzureBackup'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'AddonAzureBackupJobs'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'AddonAzureBackupAlerts'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'AddonAzureBackupPolicy'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'AddonAzureBackupStorage'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
      {
        category: 'AddonAzureBackupProtectedInstance'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
    ]
    metrics: [
      {
        category: 'Health'
        enabled: diagSettings.enableMetrics
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
    ]
  }
}

output name string = vault.name
output id string = vault.id
output systemIdentityPrincipalId string = enableSystemIdentity ? vault.identity.principalId : 'None'
