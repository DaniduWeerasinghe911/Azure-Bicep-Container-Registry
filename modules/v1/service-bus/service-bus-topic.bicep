// Bicep template to deploy Service Bus Topics

@description('The name of the Service Bus Topic to be created')
param sbTopicName string

@description('ISO 8601 Default message timespan to live value. This is the default value used when TimeToLive is not set on a message itself.')
param defaultMessageTimeToLive string = 'P10675199DT2H48M5.4775807S'

@description('Maximum size of the topic in megabytes, which is the size of the memory allocated for the topic. Default is 1024')
param maxSizeInMegabytes int = 1024

@description('Value indicating if this topic requires duplicate detection.')
param requiresDuplicateDetection bool = false

@description('ISO8601 timespan structure that defines the duration of the duplicate detection history. The default value is 10 minutes.')
param duplicateDetectionHistoryTimeWindow string = 'PT10M'

@description('Value that indicates whether server-side batched operations are enabled.')
param enableBatchedOperations bool = true

@description('Value that indicates whether the topic supports ordering.')
param supportOrdering bool = true

@description('ISO 8601 timespan idle interval after which the topic is automatically deleted. The minimum duration is 5 minutes.')
param autoDeleteOnIdle string = 'P10675199DT2H48M5.4775807S'

@description('Value that indicates whether the topic to be partitioned across multiple message brokers is enabled.')
param enablePartitioning bool = false

@description('Value that indicates whether Express Entities are enabled. An express topic holds a message in memory temporarily before writing it to persistent storage.')
param enableExpress bool = false

resource serviceBusTopic 'Microsoft.ServiceBus/namespaces/topics@2021-01-01-preview' = {
  name: sbTopicName
  properties: {
    defaultMessageTimeToLive: defaultMessageTimeToLive
    maxSizeInMegabytes: maxSizeInMegabytes
    requiresDuplicateDetection: requiresDuplicateDetection
    duplicateDetectionHistoryTimeWindow: duplicateDetectionHistoryTimeWindow
    enableBatchedOperations: enableBatchedOperations
    supportOrdering: supportOrdering
    autoDeleteOnIdle: autoDeleteOnIdle
    enablePartitioning: enablePartitioning
    enableExpress: enableExpress
  }
}
