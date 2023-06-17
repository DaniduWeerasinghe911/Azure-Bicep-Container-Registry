@description('Name of the Alert')
param alertName string

@description('Description of the Alert')
param alertDescription string

@description('Severity of alert {0,1,2,3,4}')
@allowed([
  0
  1
  2
  3
  4
])
param severity int

@description('ResourceId of the Resource in which metric is measured from')
param scopeResourceId string

@description('Location of the Resource in which metric is measured from')
param scopeResourceLocation string = resourceGroup().location

@description('Array of Action Group Resource Ids to send alerts to')
param actionGroups array

@description('Specifies whether the alert is enabled')
param enabled bool

@description('Static or Dynamic Thresold Metric.  Ensure your criterion aligns with relevant metric mode')
@allowed([
  'static'
  'dynamic'
])
param metricMode string

@description('Period of time used to monitor alert activity based on the threshold. Must be between one minute and one day. ISO 8601 duration format.')
@allowed([
  'PT1M'
  'PT5M'
  'PT15M'
  'PT30M'
  'PT1H'
  'PT6H'
  'PT12H'
  'PT24H'
])
param windowSize string

@description('How often the metric alert is evaluated represented in ISO 8601 duration format')
@allowed([
  'PT1M'
  'PT5M'
  'PT15M'
  'PT30M'
  'PT1H'
])
param evaluationFrequency string

@description('Array of criterion includes metric name, dimension values, threshold and an operator. The alert rule fires when ALL criteria are met')
param criteria array

@description('Indicates whether the alert should be auto resolved or not')
param autoMitigate bool = true

// Calculate the correct oDataType based on metric mode
var odataType = ((metricMode == 'static') ? 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria' : 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria')

// Get Resource Provider from resourceId
var scopeResourceType = split(scopeResourceId,'/')[6]

resource alertName_resource 'microsoft.insights/metricAlerts@2018-03-01' = {
  name: alertName
  location: 'global'
  properties: {
    severity: severity
    enabled: enabled
    scopes: [
      scopeResourceId
    ]
    evaluationFrequency: evaluationFrequency
    windowSize: windowSize
    criteria: {
      allOf: criteria
      'odata.type': odataType
    }
    autoMitigate: autoMitigate
    targetResourceType: scopeResourceType
    targetResourceRegion: scopeResourceLocation
    actions: [for item in actionGroups: {
      actionGroupId: item
      webHookProperties: {}
    }]
    description: alertDescription
  }
}
