// Bicep template to deploy Service Bus Topic Subscriptions

@description('The name of the Service Bus Topic subscription to be created')
param sbTopicSubscriptionName string

@description('ISO 8061 lock duration timespan for the subscription. The default value is 1 minute.')
param lockDuration string = 'PT1M'

@description('Value indicating if a subscription supports the concept of sessions.')
param requiresSession bool = false

@description('ISO 8061 Default message timespan to live value. This is the default value used when TimeToLive is not set on a message itself.')
param defaultMessageTimeToLive string = 'P10675199DT2H48M5.4775807S'

@description('Value that indicates whether a subscription has dead letter support when a message expires.')
param deadLetteringOnMessageExpiration bool = false

@description('Value that indicates whether a subscription has dead letter support on filter evaluation exceptions.')
param deadLetteringOnFilterEvaluationExceptions bool = true

@description('Number of maximum deliveries.')
param maxDeliveryCount int = 10

@description('	Value that indicates whether server-side batched operations are enabled.')
param enableBatchedOperations bool = true

@description('ISO 8061 timeSpan idle interval after which the topic is automatically deleted. The minimum duration is 5 minutes.')
param autoDeleteOnIdle string = 'P10675199DT2H48M5.4775807S'

// Resources
resource serviceBusTopicSubscription 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2021-01-01-preview' = {
  name: sbTopicSubscriptionName

  properties: {
    lockDuration: lockDuration
    requiresSession: requiresSession
    defaultMessageTimeToLive: defaultMessageTimeToLive
    deadLetteringOnMessageExpiration: deadLetteringOnMessageExpiration
    deadLetteringOnFilterEvaluationExceptions: deadLetteringOnFilterEvaluationExceptions
    maxDeliveryCount: maxDeliveryCount
    enableBatchedOperations: enableBatchedOperations
    autoDeleteOnIdle: autoDeleteOnIdle
  }
}
