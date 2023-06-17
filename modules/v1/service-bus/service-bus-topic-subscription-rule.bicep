// Bicep template to deploy Service Bus Topic Subscriptions

@description('The name of the Service Bus Topic subscription rule to be created')
param sbTopicSubscriptionRuleName string

@description('Represents the filter actions which are allowed for the transformation of a message that have been matched by a filter expression')
param action object = {}

@description('Filter type that is evaluated against a BrokeredMessage.')
@allowed([
  'CorrelationFilter'
  'SqlFilter'
])
param filterType string

@description('Details of the SQL Filter')
param sqlFilter object = {}

@description('Details of the Correlation Filter')
param correlationFilter object = {}

resource serviceBusTopicSubscriptionRule 'Microsoft.ServiceBus/namespaces/topics/subscriptions/rules@2021-01-01-preview' = {
  name: 'namespace/topics/${sbTopicSubscriptionRuleName}'
  properties: {
    action: action
    filterType: filterType
    sqlFilter: sqlFilter
    correlationFilter: correlationFilter
  }
}
