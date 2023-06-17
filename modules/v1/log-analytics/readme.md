# Log Analytics
This module will deploy a Log Analytics Workspace with solutions, data sources and linked to an automation account.

## Usage

### Example 1 - Log Analytics Workspace with solutions and data sources
``` bicep
param deploymentName string = 'logAnalytics${utcNow()}'

module logAnalytics './log-analytics.bicep' = {
  name: deploymentName
  params: {
    name: 'myLogAnalyticsWorkspace'
    retentionInDays: 30
    solutions: [
      {
        name: 'AzureActivity'
        product: 'OMSGallery/AzureActivity'
        publisher: 'Microsoft'
        promotionCode: ''
      }
    ]
    dataSources: [
      {
        name: 'Application'
        kind: 'WindowsEvent'
        properties: {
          eventLogName: 'Application'
          eventTypes: [
            {
              eventType: 'Error'
            }
            {
              eventType: 'Warning'
            }
          ]
        }
      }
      {
        name: 'LogicalDisk1'
        kind: 'WindowsPerformanceCounter'
        properties: {
          objectName: 'LogicalDisk'
          instanceName: '*'
          intervalSeconds: 360
          counterName: 'Avg Disk sec/Read'
        }
      }
    ]
  }
}
```

### Example 2 - Log Analytics Workspace with solutions, data sources and linked to an automation account
``` bicep
param deploymentName string = 'logAnalytics${utcNow()}'

module logAnalytics './log-analytics.bicep' = {
  name: deploymentName
  params: {
    name: 'myLogAnalyticsWorkspace'
    retentionInDays: 30
    automationAccountName: '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourcegroups/example-dev-rg/providers/Microsoft.Automation/AutomationAccounts/myAutomationAccount'
    solutions: [
      {
        name: 'AzureActivity'
        product: 'OMSGallery/AzureActivity'
        publisher: 'Microsoft'
        promotionCode: ''
      }
    ]
    dataSources: [
      {
        name: 'Application'
        kind: 'WindowsEvent'
        properties: {
          eventLogName: 'Application'
          eventTypes: [
            {
              eventType: 'Error'
            }
            {
              eventType: 'Warning'
            }
          ]
        }
      }
      {
        name: 'LogicalDisk1'
        kind: 'WindowsPerformanceCounter'
        properties: {
          objectName: 'LogicalDisk'
          instanceName: '*'
          intervalSeconds: 360
          counterName: 'Avg Disk sec/Read'
        }
      }
    ]
  }
}
```

### Example 3 - Log Analytics Workspace with solutions, data sources, delete lock and diagnostic logs enabled
``` bicep
param deploymentName string = 'logAnalytics${utcNow()}'

var tags = {
  Purpose: 'Sample Bicep Template'
  Environment: 'Development'
  Owner: 'sample.user@arinco.com.au'
}

var diagnostics = {
  name: 'diag-log'
  workspaceId: '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourcegroups/example-dev-rg/providers/microsoft.operationalinsights/workspaces/example-dev-log'
  storageAccountId: '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourcegroups/example-dev-rg/providers/microsoft.storage/storageAccounts/exampledevst'
  eventHubAuthorizationRuleId: 'Endpoint=sb://example-dev-ehns.servicebus.windows.net/;SharedAccessKeyName=DiagnosticsLogging;SharedAccessKey=xxxxxxxxx;EntityPath=example-hub-namespace'
  eventHubName: 'StorageDiagnotics'
  enableLogs: true
  enableMetrics: false
  retentionPolicy: {
    days: 0
    enabled: false
  }
}

module logAnalytics './log-analytics.bicep' = {
  name: deploymentName
  params: {
    name: 'myLogAnalyticsWorkspace'
    retentionInDays: 30    
    solutions: [
      {
        name: 'AzureActivity'
        product: 'OMSGallery/AzureActivity'
        publisher: 'Microsoft'
        promotionCode: ''
      }
    ]
    dataSources: [
      {
        name: 'Application'
        kind: 'WindowsEvent'
        properties: {
          eventLogName: 'Application'
          eventTypes: [
            {
              eventType: 'Error'
            }
            {
              eventType: 'Warning'
            }
          ]
        }
      }
      {
        name: 'LogicalDisk1'
        kind: 'WindowsPerformanceCounter'
        properties: {
          objectName: 'LogicalDisk'
          instanceName: '*'
          intervalSeconds: 360
          counterName: 'Avg Disk sec/Read'
        }
      }
    ]
    enableResourceLock: true
    diagsettings: diagnostics 
  }
}
```