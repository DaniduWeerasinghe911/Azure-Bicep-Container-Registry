# Storage Account
This module will deploy a General Purpose V2 Storage Account with common security settings.

## Usage

### Example - Storage account with diagnostics and resource lock

``` bicep
param deploymentName string = 'storage${utcNow()}'

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

module storage './storage.bicep' = {
  name: deploymentName
  params: {
    tags: tags
    storageAccountName: 'mystorageaccount'
    storageSku: 'Standard_LRS'
    storageTier: 'Hot'
    deleteRetentionPolicy: 7
    enableResourceLock: true
    diagsettings: diagnostics
  }
}