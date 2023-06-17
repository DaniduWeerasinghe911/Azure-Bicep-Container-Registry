# Virtual Network Gateway
This module will deploy attached a Virtual Network Gateway to an existing network

## Usage


### Example 1 - Virtual Network Gateway attached to virtual network
``` bicep
module gateway 'demo/modules/vnet-gateway/vnet-gateway.bicep' = {
  name: 'deploy_virtualGateway'
  params: {
    gatewayType: 'Vpn'
    vnetGatewayName: 'example_name'
    sku: 'Basic'
    vnetName: 'example-network'
    vnetResourceGroup: 'example-rg'
  }
}

```

### Example 2 - Virtual Network Gateway attached to virtual network with diagnostics

``` bash
az deployment group create --resource-group testrg --template-file vnet-gateway.bicep
```

``` bicep

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

module gateway 'demo/modules/vnet-gateway/vnet-gateway.bicep' = {
  name: 'deploy_virtualGateway'
  params: {
    gatewayType: 'Vpn'
    vnetGatewayName: 'example_name'
    sku: 'Basic'
    vnetName: 'example-network'
    vnetResourceGroup: 'example-rg'
    diagSettings: diagnostics
    enableResourceLock: true
  }
}

