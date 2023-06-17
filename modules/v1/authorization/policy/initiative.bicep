// This is a Bicep module to create Initiative Definitions
targetScope = 'managementGroup'

// Set params here

param policyDefinitions array
param displayName string
param description string
param name string

// Set vars here


// Create Custom Initiatives
resource create_custom_initiative 'Microsoft.Authorization/policySetDefinitions@2020-09-01' = {
  name: name
  properties: {
    policyType: 'Custom'
    displayName: displayName
    description: description
    policyDefinitions:  [for (policy, i) in policyDefinitions: {
      policyDefinitionId: policy.policyDefinitionId
      parameters: policy.parameters
    }]
  }
}
