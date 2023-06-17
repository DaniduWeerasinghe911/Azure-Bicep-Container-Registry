// Helper Bicep Module to assign SQL Server Managed Identity access into Storage Account used for storing audit logs
// This is required due to limitations of using scopes when crossing deployment boundaries (i.e. SQL server config is different resource group to where storage account is)
// It is expected the deployment of this module is scoped (by the parent module) to the resource group that hosts the Storage Account 

@description('Name of Storage Account to store Vulnerability Assessments.')
param storageName string

@description('Resource Id of SQL Server.')
param sqlServerId string

// Create a GUID for the purposes of assigning role permissions
var uniqueRoleGuid = guid(storage.id, StorageBlobContributor, sqlServerId)
// Standard role ID
var StorageBlobContributor = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')

// Get existing Storage Account Object
resource storage 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storageName
}

// Assign Role Defintion to storage account
resource roleDefinition 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: uniqueRoleGuid
  scope: storage
  properties: {
    roleDefinitionId: StorageBlobContributor
    principalId: reference(sqlServerId, '2018-06-01-preview', 'Full').identity.principalId
    principalType: 'ServicePrincipal'
  }
}
