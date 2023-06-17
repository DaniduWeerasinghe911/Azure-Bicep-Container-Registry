// Azure Firewall Policy

@description('Name of the firewall policy.')
param policyName string

@description('Location of the resource.')
param location string = resourceGroup().location

@description('The operation mode for Threat Intel.')
@allowed([
  'Alert'
  'Deny'
  'Off'
])
param threatIntelMode string = 'Alert'

@description('Object containing resource tags.')
param tags object = {}

@description('Enable a Can Not Delete Resource Lock.  Useful for production workloads.')
param enableResourceLock bool = false

// Resource Definition
resource firewallPolicy 'Microsoft.Network/firewallPolicies@2021-02-01' = {
  name: policyName
  location: location
  tags: !empty(tags) ? tags : json('null')  
  properties: {
    threatIntelMode: threatIntelMode
    
  }
}

// Output Resource Name and Resource Id as a standard to allow module referencing.
output name string = firewallPolicy.name
output id string = firewallPolicy.id

