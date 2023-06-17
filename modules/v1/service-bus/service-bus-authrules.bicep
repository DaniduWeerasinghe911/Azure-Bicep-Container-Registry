// Bicep template to deploy Service Bus Authorization Rules

@description('The name of the Service Bus Authorisation Rules to be created')
param sbAuthRulesName string

@description('List of rights to be assigned')
param rights array

// Resources

resource serviceBusAuthRule 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2021-01-01-preview' = {
  name: 'namespaces/${sbAuthRulesName}'
  properties: {
    rights: rights
  }
}
