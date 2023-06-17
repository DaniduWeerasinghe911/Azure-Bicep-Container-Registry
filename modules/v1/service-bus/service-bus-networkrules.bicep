// Bicep template to deploy Service Bus Network Rule Sets

@description('The name of the Service Bus Network Rule Set to be created')
param sbRuleSetName string

@description('Action for rule set to take')
@allowed([
  'Allow'
  'Deny'
])
param defaultAction string = 'Deny'

@description('List of virtual network rules to be assigned')
param virtualNetworkRules array = []

@description('List of IP rules to be assigned')
param ipRules array = []

// Resources

resource serviceBusNetworkRule 'Microsoft.ServiceBus/namespaces/networkRuleSets@2021-01-01-preview' = {
  name: 'namespaces/${sbRuleSetName}'
  properties: {
    defaultAction: defaultAction
    virtualNetworkRules: virtualNetworkRules
    ipRules: ipRules
  }
}
