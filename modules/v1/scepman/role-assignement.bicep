@description('Key Vault Name')
param keyvaultName string

@description('Shared Services Resource Group Name')
param shdSvcsRgName string

@description('Service Principal ID')
param permittedPrincipalId string

resource SCEPmanVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  scope: resourceGroup(shdSvcsRgName)
  name: keyvaultName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(SCEPmanVault.id, permittedPrincipalId, subscriptionResourceId('Microsoft.Authorization/roleDefinitions','00482a5a-887f-4fb3-b363-3b7fe8e74483'))
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions','00482a5a-887f-4fb3-b363-3b7fe8e74483')
    principalId: permittedPrincipalId
    principalType: 'ServicePrincipal'
  }
}
