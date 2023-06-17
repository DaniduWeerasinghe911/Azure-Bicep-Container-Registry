@description('The list of email receivers that are part of this action group.')
param emailReceivers array = [
]

@description('The list of email receivers that are part of this action group.')
param resourceScope array = [
  subscription().subscriptionId
]

resource actionGroup 'Microsoft.Insights/actionGroups@2019-06-01' = {
  name: 'resource-alerts'
  location: 'Global'
  properties: {
    groupShortName: 'res-alerts'
    enabled: true
    emailReceivers: emailReceivers
  }
}

resource metricAlerts_Available_Memory_Bytes 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'metricAlerts_Available_Memory_Bytes'
  location: 'global'
  properties: {
    criteria: {
      allOf: [
          {
              threshold: 1000000000
              name: 'Metric1'
              metricNamespace: 'Microsoft.Compute/virtualMachines'
              metricName: 'Available Memory Bytes'
              operator: 'LessThan'
              timeAggregation: 'Average'
              criterionType: 'StaticThresholdCriterion'
          }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
  }
    enabled: true
    evaluationFrequency: 'PT5M'
    scopes: resourceScope
    severity: 3
    windowSize: 'PT5M'
    actions:[
      {
        actionGroupId: actionGroup.id
        webHookProperties: {}
    }
    ]
  }
}
