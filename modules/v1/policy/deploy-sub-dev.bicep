// Set Bicep deployment scope
targetScope = 'managementGroup'

@description('Resource Deployment Location')
param location string

@description('List of Policy Definitions ')
param policyDefinitions array

resource SecGovAssign 'Microsoft.Authorization/policyAssignments@2021-06-01' = {
  name: 'SecGovAssign'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'Custom Azure Security Benchmark - Symal'
    description: ''
    enforcementMode: 'Default'
    policyDefinitionId: SecGovDef.id
    nonComplianceMessages: [
      {
        message: 'Denied by Azure Security Benchmark @ contact Symal Infra team'
      }
    ]
  }
}

// Create a policy initiative for Security Governance  containing built-in policies
resource SecGovDef 'Microsoft.Authorization/policySetDefinitions@2020-09-01' = {
  name: 'SecGovDef'
  properties: {
    displayName: 'Custom Azure Security Benchmark - Symal Software Solutions'
    policyType: 'Custom'
    description: 'Applies baseline security governance'
    metadata: {
      version: '0.1.0'
      category: 'Custom'
      source: 'globalbao/azure-policy-as-code'
    }
    policyDefinitions: policyDefinitions
  }
}
//listOfAllowedLocations   australiaeast;australiasoutheast
// Create an role assignment for managed identity
resource SecGovRA1 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(SecGovAssign.name, SecGovAssign.type, managementGroup().id)
  properties: {
    principalId: SecGovAssign.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: '/providers/microsoft.authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c' // Contributor
  }
}
