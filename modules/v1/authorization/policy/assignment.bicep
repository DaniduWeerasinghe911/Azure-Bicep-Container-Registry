// This is a Bicep module to create Policy Assignments
targetScope = 'managementGroup'

// Define Params here to be passed to the module
param assignmentIdentityLocation string
param assignmentEnforcementMode string
param assignmentPolicyId string
param assignmentName string
param assignmentDisplayName string
param assignmentDescription string

// Resources
resource policyAssignment 'Microsoft.Authorization/policyAssignments@2020-09-01' = {
  name: assignmentName
  location: assignmentIdentityLocation
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: assignmentDisplayName
    description: assignmentDescription
    enforcementMode: assignmentEnforcementMode
    policyDefinitionId: assignmentPolicyId
  }
}

resource assignmentRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(policyAssignment.name, policyAssignment.type, policyAssignment.id)
  properties: {
    principalId: policyAssignment.identity.principalId
    roleDefinitionId: '/providers/microsoft.authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c' // contributor RBAC role for deployIfNotExists/modify effects
  }
}

// Outputs
output assignmentNames string = policyAssignment.name
output roleAssignmentIDs string = assignmentRoleAssignment.id
output assignmentIDs string = policyAssignment.id
