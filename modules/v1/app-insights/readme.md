# App Insights
This module will deploy an workspace-based App Insights instance.
[Reference](https://docs.microsoft.com/en-us/azure/azure-monitor/app/create-workspace-resource)

## Usage

### Example - App Insights with existing Log Analytics Workspace

``` bicep
param deploymentName string = 'appinsights${utcNow()}'

var tags = {
  Purpose: 'Sample Bicep Template'
  Environment: 'Development'
  Owner: 'sample.user@arinco.com.au'
}

// Existing Log Workspace
resource workspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  scope: resourceGroup('xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx','example-rg')
  name: 'example-log'
}

module appinsights './app-insights.bicep' = {
  name: deploymentName
  params: {
    name: 'example-ai'
    workspaceResourceId: workspace.id
    tags: tags
    enableResourceLock: true
  }
}
```
