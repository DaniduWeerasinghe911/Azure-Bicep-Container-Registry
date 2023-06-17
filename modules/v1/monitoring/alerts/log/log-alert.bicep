@description('Name of the Alert')
param alertName string

@description('Location of resource')
param location string = resourceGroup().location

@description('Description of the Alert')
param alertDescription string

@description('Sets Alert to enabled/disabled')
param status string = 'true'

@description('How often, in minutes, to run query')
param frequency int

@description('Over what time period, in minutes, to measure query')
param period int

@description('Severity of Alert')
@allowed([
  '0'
  '1'
  '2'
  '3'
  '4'
])
param severity string

@description('Operator to compare results against')
@allowed([
  'GreaterThan'
  'LessThan'
])
param triggerOperator string

@description('Threshold value to trigger')
param triggerThreshold int

@description('Array of Action Group Resource Ids to send alerts to')
param actionGroups array

@description('Ensure this log query is compressed, sanitised and characters are escaped')
param logQuery string

@description('ResourceId of the Log Analytics Workspace or App Insights Resource')
param sourceResourceId string

@description('Amount of time, in minutes, to supress alert upon creation')
param supressTime int = 0

@description('Optional. Custom email subject header')
param emailSubject string = ''

@description('Optional. Custom payload to be sent for all webhook URI in Azure action group')
param customPayload string = ''

resource alertName_resource 'Microsoft.Insights/scheduledQueryRules@2018-04-16' = {
  name: alertName
  location: location
  properties: {
    description: alertDescription
    enabled: status
    source: {
      query: logQuery
      dataSourceId: sourceResourceId
      queryType: 'ResultCount'
    }
    schedule: {
      frequencyInMinutes: frequency
      timeWindowInMinutes: period
    }
    action: {
      'odata.type': 'Microsoft.WindowsAzure.Management.Monitoring.Alerts.Models.Microsoft.AppInsights.Nexus.DataContracts.Resources.ScheduledQueryRules.AlertingAction'
      severity: severity
      throttlingInMin: supressTime
      aznsAction: {
        actionGroup: actionGroups
        emailSubject: (empty(emailSubject) ? json('null') : emailSubject)
        customWebhookPayload: (empty(customPayload) ? json('null') : customPayload)
      }
      trigger: {
        thresholdOperator: triggerOperator
        threshold: triggerThreshold
      }
    }
  }
}
