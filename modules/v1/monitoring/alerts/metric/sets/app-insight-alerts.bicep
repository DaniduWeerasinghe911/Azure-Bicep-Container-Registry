@description('ResourceId of the App Insights')
param appInsightsResourceId string

@description('Array of Action Group ResourceIds to send alerts')
param actionGroups array

@description('Determines if alerts are deployed in an enabled or disabled state.')
param enabled bool = true

@description('Array of Cloud Roles to scope these alerts against as a metric dimensions.')
param cloudRoles array

@description('Descriptive name for Cloud Roles to put in Alert Name.')
param cloudRolesDescription string

@description('Severity for these alerts.')
param severity int

@description('Sensitivity of Dynamic Alerts.')
param alertSensitivity string = 'Medium'

@description('Number of Evaluation Periods.')
param numberOfEvaluationPeriods int = 4

@description('Minimum Failing Periods to Alert.')
param minFailingPeriodsToAlert int = 4

@description('Available Memory Bytes to use for Memory Util Alert.')
param memoryAvailBytes int = 52428800

@description('Percentage CPU Threshold to use for CPU Util Alert')
param cpuThreshold int = 90

module Dependency_Call_Failure '../metric-alert.bicep' = {
  name: '${cloudRolesDescription} - Dependency Call Failure'
  params: {
    alertName: '${cloudRolesDescription} - Dependency Call Failure'
    alertDescription: 'Dependency Call Counts are higher than usual for the past ${numberOfEvaluationPeriods} evaluations, with an evaluation window of 5 minutes (Dynamic Threshold: ${alertSensitivity}).'
    scopeResourceId: appInsightsResourceId
    severity: severity
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    metricMode: 'dynamic'
    criteria: [
      {
        criterionType: 'DynamicThresholdCriterion'
        name: 'Criterion1'
        metricName: 'dependencies/failed'
        dimensions: [
          {
            name: 'cloud/roleName'
            operator: 'Include'
            values: cloudRoles
          }
        ]
        operator: 'GreaterThan'
        alertSensitivity: alertSensitivity
        failingPeriods: {
          numberOfEvaluationPeriods: numberOfEvaluationPeriods
          minFailingPeriodsToAlert: minFailingPeriodsToAlert
        }
        timeAggregation: 'Count'
      }
    ]
    actionGroups: actionGroups
    enabled: enabled 
  }
}

module Total_Exception_Count '../metric-alert.bicep' = {
  name: '${cloudRolesDescription} - Total Exception Count'
  params: {
    alertName: '${cloudRolesDescription} - Total Exception Count'
    alertDescription: 'Total Exception Counts are higher than usual for the past ${numberOfEvaluationPeriods} evaluations, with an evaluation window of 5 minutes (Dynamic Threshold: ${alertSensitivity}).'
    scopeResourceId: appInsightsResourceId
    severity: severity
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    metricMode: 'dynamic'
    criteria: [
      {
        criterionType: 'DynamicThresholdCriterion'
        name: 'Criterion1'
        metricName: 'exceptions/count'
        dimensions: [
          {
            name: 'cloud/roleName'
            operator: 'Include'
            values: cloudRoles
          }
        ]
        operator: 'GreaterThan'
        alertSensitivity: alertSensitivity
        failingPeriods: {
          numberOfEvaluationPeriods: numberOfEvaluationPeriods
          minFailingPeriodsToAlert: minFailingPeriodsToAlert
        }
        timeAggregation: 'Count'
      }
    ]
    actionGroups: actionGroups
    enabled: enabled 
  }
}

module Browser_Exception_Count '../metric-alert.bicep' = {
  name: '${cloudRolesDescription} - Browser Exception Count'
  params: {
    alertName: '${cloudRolesDescription} - Browser Exception Count'
    alertDescription: 'Browser Exception Count are higher than usual for the past ${numberOfEvaluationPeriods} evaluations, with an evaluation window of 5 minutes (Dynamic Threshold: ${alertSensitivity}).'
    scopeResourceId: appInsightsResourceId
    severity: severity
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    metricMode: 'dynamic'
    criteria: [
      {
        criterionType: 'DynamicThresholdCriterion'
        name: 'Criterion1'
        metricName: 'exceptions/browser'
        dimensions: [
          {
            name: 'cloud/roleName'
            operator: 'Include'
            values: cloudRoles
          }
        ]
        operator: 'GreaterThan'
        alertSensitivity: alertSensitivity
        failingPeriods: {
          numberOfEvaluationPeriods: numberOfEvaluationPeriods
          minFailingPeriodsToAlert: minFailingPeriodsToAlert
        }
        timeAggregation: 'Count'
      }
    ]
    actionGroups: actionGroups
    enabled: enabled 
  }
}

module Server_Exception_Count '../metric-alert.bicep' = {
  name: '${cloudRolesDescription} - Server Exception Count'
  params: {
    alertName: '${cloudRolesDescription} - Server Exception Count'
    alertDescription: 'Server Exception Count are higher than usual for the past ${numberOfEvaluationPeriods} evaluations, with an evaluation window of 5 minutes (Dynamic Threshold: ${alertSensitivity}).'
    scopeResourceId: appInsightsResourceId
    severity: severity
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    metricMode: 'dynamic'
    criteria: [
      {
        criterionType: 'DynamicThresholdCriterion'
        name: 'Criterion1'
        metricName: 'exceptions/server'
        dimensions: [
          {
            name: 'cloud/roleName'
            operator: 'Include'
            values: cloudRoles
          }
        ]
        operator: 'GreaterThan'
        alertSensitivity: alertSensitivity
        failingPeriods: {
          numberOfEvaluationPeriods: numberOfEvaluationPeriods
          minFailingPeriodsToAlert: minFailingPeriodsToAlert
        }
        timeAggregation: 'Count'
      }
    ]
    actionGroups: actionGroups
    enabled: enabled 
  }
}

module Request_Failure_Count '../metric-alert.bicep' = {
  name: '${cloudRolesDescription} - Request Failure Count'
  params: {
    alertName: '${cloudRolesDescription} - Request Failure Count'
    alertDescription: 'Request Failure Count are higher than usual for the past ${numberOfEvaluationPeriods} evaluations, with an evaluation window of 5 minutes (Dynamic Threshold: ${alertSensitivity}).'
    scopeResourceId: appInsightsResourceId
    severity: severity
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    metricMode: 'dynamic'
    criteria: [
      {
        criterionType: 'DynamicThresholdCriterion'
        name: 'Criterion1'
        metricName: 'requests/failed'
        dimensions: [
          {
            name: 'cloud/roleName'
            operator: 'Include'
            values: cloudRoles
          }
        ]
        operator: 'GreaterThan'
        alertSensitivity: alertSensitivity
        failingPeriods: {
          numberOfEvaluationPeriods: numberOfEvaluationPeriods
          minFailingPeriodsToAlert: minFailingPeriodsToAlert
        }
        timeAggregation: 'Count'
      }
    ]
    actionGroups: actionGroups
    enabled: enabled 
  }
}

module Request_5xx_Errors '../metric-alert.bicep' = {
  name: '${cloudRolesDescription} - Request HTTP Error 5xx'
  params: {
    alertName: '${cloudRolesDescription} - Request HTTP Error 5xx'
    alertDescription: 'Application HTTP Error 5xx Request Count are higher than usual for the past ${numberOfEvaluationPeriods} evaluations, with an evaluation window of 5 minutes (Dynamic Threshold: ${alertSensitivity}).'
    scopeResourceId: appInsightsResourceId
    severity: severity
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    metricMode: 'dynamic'
    criteria: [
      {
        criterionType: 'DynamicThresholdCriterion'
        name: 'Criterion1'
        metricName: 'requests/failed'
        dimensions: [
          {
            name: 'cloud/roleName'
            operator: 'Include'
            values: cloudRoles
          }
          {
            name: 'request/resultCode'
            operator: 'Include'
            values: [
              '501'
              '502'
              '503'
              '504'
            ]
          }
        ]
        operator: 'GreaterThan'
        alertSensitivity: alertSensitivity
        failingPeriods: {
          numberOfEvaluationPeriods: numberOfEvaluationPeriods
          minFailingPeriodsToAlert: minFailingPeriodsToAlert
        }
        timeAggregation: 'Count'
      }
    ]
    actionGroups: actionGroups
    enabled: enabled 
  }
}

module Memory_Utilisation '../metric-alert.bicep' = {
  name: '${cloudRolesDescription} - Memory Utilisation'
  params: {
    alertName: '${cloudRolesDescription} - Memory Utilisation'
    alertDescription: 'Application Available memory below threshold.'
    scopeResourceId: appInsightsResourceId
    severity: severity
    evaluationFrequency: 'PT15M'
    windowSize: 'PT15M'
    metricMode: 'static'
    criteria: [
      {
        name: 'Criterion'
        metricNamespace: 'microsoft.insights/components'
        metricName: 'performanceCounters/memoryAvailableBytes'
        dimensions: [
          {
            name: 'cloud/roleInstance'
            operator: 'Include'
            values: cloudRoles
          }
        ]
        operator: 'LessThan'
        threshold: memoryAvailBytes
        timeAggregation: 'Average'
      }
    ]
    actionGroups: actionGroups
    enabled: enabled 
  }
}

module CPU_Utilisation '../metric-alert.bicep' = {
  name: '${cloudRolesDescription} - CPU Utilisation'
  params: {
    alertName: '${cloudRolesDescription} - CPU Utilisation'
    alertDescription: 'Application CPU utilisation above threshold.'
    scopeResourceId: appInsightsResourceId
    severity: severity
    evaluationFrequency: 'PT15M'
    windowSize: 'PT15M'
    metricMode: 'static'
    criteria: [
      {
        name: 'Criterion'
        metricNamespace: 'microsoft.insights/components'
        metricName: 'performanceCounters/processorCpuPercentage'
        dimensions: [
          {
            name: 'cloud/roleInstance'
            operator: 'Include'
            values: cloudRoles
          }
        ]
        operator: 'GreaterThan'
        threshold: cpuThreshold
        timeAggregation: 'Average'
      }
    ]
    actionGroups: actionGroups
    enabled: enabled 
  }
}
