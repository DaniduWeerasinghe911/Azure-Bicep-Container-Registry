# Azure Firewall
This module will deploy a Azure Firewall.  There are multiple variations.
- Azure Firewall - Normal setup for Azure Firewall
- Azure Firewall - Forced Tunnel - Required for those environments that have forced tunnelling enabled on their ExpressRoute

*Note* Azure Firewall must be deployed into the same resource group as the virtual network.

## Usage

### Example - Azure Firewall with Forced Tunnel Mode with diagnostics and resource lock

``` bicep

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

module azfirewall '../../../v1/az-firewall/az-firewall-forced-tunnel.bicep' = {
  scope: resourceGroup(rg_network.name) 
  name: 'deploy_firewall'
  params: {
    firewallName: firewallName
    threatIntelMode: 'Alert' 
    firewallSubnetId: '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/example-dev-rg/providers/Microsoft.Network/virtualNetworks/example-vnet/subnets/AzureFirewallSubnet'
    managementSubnetId: '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/example-dev-rg/providers/Microsoft.Network/virtualNetworks/example-vnet/subnets/AzureFirewallManagementSubnet'
    skuName: 'AZFW_VNet'
    skuTier: 'Standard'
    enableResourceLock: false
    diagSettings: diagSettings
    tags: tags
  }
}

module firewallRules '../../../v1/az-firewall/az-firewall.rules.bicep' = {
  scope: resourceGroup(rg_network.name) 
  name: 'deploy_firewallRules'
  params: {
    firewallPolicyName: 'sample-policy'
    priority: 300
    ruleCollections: [
      {
        name: 'Azure-Management'
        priority: 105
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'from-azuremgmt-to-any'
            ipProtocols: [
              'Any'
            ]
            sourceAddresses: [
              '168.63.129.16'
            ]
            sourceIpGroups: []
            destinationAddresses: [
              '*'
            ]
            destinationIpGroups: []
            destinationFqdns: []
            destinationPorts: [
              '*'
            ]
          }
        ]
      }
    ]
  }
  dependsOn: [
    azfirewall
  ]
}