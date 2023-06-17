# Web Application
This module will deploy a HTTPS Web Application with optional private endpoint.

The module will create an application with the name 'webapp-{appName}-{uniqueResourceGroup}' to make it unique

## Usage

### Example 1 - Web Application with .NET 5.0
``` bicep
module webApp './app-windows.bicep' = {
  name: 'deploymentName'
  params: {
    appName: 'webapplicationName'
    enableResourceLock: true
    netFrameworkVersion: '5.0'
    serverFarmId: 'appServicePlanName'
    subnetName: 'subnetName'
    vnetName: 'vnetName'
  }
}
```

### Example 2 - Web Application with .NET 5.0 and a private endpoint
``` bicep
module webApp 'demo/modules/app/app-windows.bicep' = {
  name: 'deploymentName'
  params: {
    appName: 'webapplicationName'
    enableResourceLock: true
    netFrameworkVersion: '5.0'
    serverFarmId: 'appServicePlanName'
    subnetName: 'subnetName'
    vnetName: 'vnetName'
  }
}

module privateEndpoint 'demo/modules/app/app-windows-PE.bicep' = {
  name: '${webApp}-pe'
  params: {
    dnsZoneResourceGroup: 'example-dev-rg'
    dnsZoneSubscriptionId: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
    id: app.outputs.appID
    resourceName: app.outputs.appName
    subnetId: '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourcegroups/example-dev-rg/providers/Microsoft.Network/virtualNetworks/example-dev-vnet/subnets/example-subnet'
  }
}
```

### Example 3 - Web Application with diagnostics

``` bash
az deployment group create --resource-group testrg --name webapplication --template-file app-windows.bicep --parameters app-windows.parameters.json
```

app-windows.bicep
``` bicep
module webApp 'demo/modules/app/app-windows.bicep' = {
  name: 'deploymentName'
  params: {
    serverFarmId: 'appServicePlanName'
    subnetName: 'subnetName'
    vnetName: 'vnetName'
  }
}

```
storage.parameters.json
``` json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "appName": {
      "value": "web-app-name"
    },
     "netFrameworkVersion": {
      "value": "5.0" 
    },
    "tags": {
      "value": {
        "Purpose": "Sample Bicep Tempalte",
        "Environment": "Development",
        "Owner": "sample.user@arinco.com.au"
      }
    },
    "enableResourceLock": {
      "value": true
    },
    "diagSettings": {
      "value": { 
        "name": "diag-log",
        "workspaceId": "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourcegroups/example-dev-rg/providers/microsoft.operationalinsights/workspaces/example-dev-log",
        "storageAccountId": "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourcegroups/example-dev-rg/providers/microsoft.storage/storageAccounts/exampledevst",
        "eventHubAuthorizationRuleId": "Endpoint=sb://example-dev-ehns.servicebus.windows.net/;SharedAccessKeyName=DiagnosticsLogging;SharedAccessKey=xxxxxxxxx;EntityPath=example-hub-namespace", 
        "eventHubName": "StorageDiagnotics",
        "enableLogs": true,
        "enableMetrics": false,
        "retentionPolicy": {
          "days": 0,
          "enabled": false
        }
      }
    }
  }
}
```