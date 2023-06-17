@description('Name of the firewall.')
param firewallPolicyName string

@description('Set firewall rules')
param ruleCollections array

@description('')
param priority int

resource symbolicname 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2021-02-01' = {
  name: '${firewallPolicyName}/ruleCollections'
  properties: {
    priority: priority
    ruleCollections: empty(ruleCollections) ? [] : ruleCollections
  }
}
