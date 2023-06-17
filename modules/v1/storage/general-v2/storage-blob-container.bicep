@description('Name of the Resource for which to create the Private Endpoint')
param blobName string

@description('Name of the Resource for which to create the Private Endpoint')
param storageAccountName string


var blobContainer = '${storageAccountName}/default/${blobName}'

resource blobcontainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = {
  name: blobContainer
  properties: {
   /* defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
   /* immutableStorageWithVersioning: {
      enabled: false
    }
    metadata: {}
    publicAccess: 'None'
    
  */}
}
