// Bicep Module to deploy an Azure Cache for Redis service
@description('Specify the name of the Azure Redis Cache to create.')
param redisCacheName string

@description('The location of the Redis Cache. For best performance, use the same location as the app to be used with the cache.')
param location string = resourceGroup().location

@description('Specify the pricing tier of the new Azure Redis Cache.')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param redisCacheSKU string = 'Standard'

@description('Specify the family for the sku. C = Basic/Standard, P = Premium')
@allowed([
  'C'
  'P'
])
param redisCacheFamily string = 'C'

@description('Name of the storage account. Only valid for Premium SKU')
param storageAccountName string = ''

@description('Specify the size of the new Azure Redis Cache instance. Valid values: for C (Basic/Standard) family (0, 1, 2, 3, 4, 5, 6), for P (Premium) family (1, 2, 3, 4)')
@allowed([
  0
  1
  2
  3
  4
  5
  6
])
param redisCacheCapacity int = 1

@description('Specify a boolean value that indicates whether to allow access via non-SSL ports.')
param enableNonSslPort bool = false

@description('Redis version. Only major version will be used in PUT/PATCH request with current valid values: (4, 6)')
param redisVersion string = '6'

@description('Object containing resource tags.')
param tags object = {}

@description('Enable a Can Not Delete Resource Lock.  Useful for production workloads.')
param enableResourceLock bool = false

@description('Object containing diagnostics settings. If not provided diagnostics will not be set.')
param diagSettings object = {}

//Resources
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = if (!empty(storageAccountName)) {
  name: storageAccountName
}

var cacheAccountKey = empty(storageAccount) ? '' : storageAccount.listKeys().keys[0].value

resource cache 'Microsoft.Cache/Redis@2020-12-01' = {
  name: redisCacheName
  location: location
  tags: tags
  properties: {
    enableNonSslPort: enableNonSslPort
    minimumTlsVersion: '1.2'
    sku: {
      capacity: redisCacheCapacity
      family: redisCacheFamily
      name: redisCacheSKU
    }
    redisConfiguration: {
      'rdb-backup-enabled': empty(storageAccount) ? 'false' : 'true'
      'rdb-backup-frequency': '60'
      'rdb-backup-max-snapshot-count': '1'
      'rdb-storage-connection-string': empty(storageAccount) ? '' : 'DefaultEndpointsProtocol=https;BlobEndpoint=https://${storageAccount.name}.blob.${environment().suffixes.storage};AccountName=${storageAccount.name};AccountKey=${cacheAccountKey}'
    }
    redisVersion: redisVersion
  }
}

// Diagnostics
resource diagnostics 'Microsoft.insights/diagnosticsettings@2017-05-01-preview' = if (!empty(diagSettings)) {
  name: empty(diagSettings) ? 'dummy-value' : diagSettings.name
  scope: cache

  properties: {
    workspaceId: empty(diagSettings.workspaceId) ? json('null') : diagSettings.workspaceId
    storageAccountId: empty(diagSettings.storageAccountId) ? json('null') : diagSettings.storageAccountId
    eventHubAuthorizationRuleId: empty(diagSettings.eventHubAuthorizationRuleId) ? json('null') : diagSettings.eventHubAuthorizationRuleId
    eventHubName: empty(diagSettings.eventHubName) ? json('null') : diagSettings.eventHubName
    
    logs: [
      {
        category: 'ConnectedClientList'
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
  name: '${redisCacheName}-delete-lock'
  scope: cache
  properties: {
    level: 'CanNotDelete'
    notes: 'Enabled as part of IaC Deployment'
  }
}

// Output Resource Name and Resource Id as a standard to allow module referencing.
output name string = cache.name
output id string = cache.id
