// Azure Firewall that is deployed in 'normal' mode (not forced tunnel)

@description('Name of the firewall.')
param firewallName string

@description('The SKU Tier of Azure Firewall.')
@allowed([
  'Standard'
  'Premium'
])
param skuTier string

@description('The SKU Name of Azure Firewall.  Set to AZFW_Hub only if attaching to a Virtual Hub.')
@allowed([
  'AZFW_VNet'
  'AZFW_Hub'
])
param skuName string = 'AZFW_VNet'

@description('The Id of the firewall subnet.')
param firewallSubnetId string

@description('The Id of the firewall management subnet.')
param firewallManagementSubnetId string

@description('The Id of the firewall policy.')
param firewallPolicyId string

@description('Additional IP addresses')
param firewallIPAdditionalIPAddrs array = []

@description('Location of the resource.')
param location string = resourceGroup().location

@description('Object containing resource tags.')
param tags object = {}

@description('Enable a Can Not Delete Resource Lock.  Useful for production workloads.')
param enableResourceLock bool = false

@description('Object containing diagnostics settings. If not provided diagnostics will not be set.')
param diagSettings object = {}

// Resource Names
param publicIpName string = '${firewallName}-pip'
param managementPublicIpName string = '${firewallName}-management-pip'
//param threadIntelPolicyName string = '${firewallName}-threat-intel-policy'

// Firwall Public IP Resource Definition
module publicIp '../networking/public-ip/public-ip.bicep' = {
  name: 'deploy_inbound_public_ip'
  params:{
    publicIpName: publicIpName
    location: location
    tags: tags
    sku: 'Standard'
    publicIPAllocationMethod: 'Static'
    diagSettings: diagSettings
    enableResourceLock: enableResourceLock
  }
}

module managementpublicIp '../networking/public-ip/public-ip.bicep' = {
  name: 'deploy_inbound_management_public_ip'
  params:{
    publicIpName: managementPublicIpName
    location: location
    tags: tags
    sku: 'Standard'
    publicIPAllocationMethod: 'Static'
    diagSettings: diagSettings
    enableResourceLock: enableResourceLock
  }
  dependsOn:[
    publicIp
  ]
}

// Firewall Resource Definition
resource firewall 'Microsoft.Network/azureFirewalls@2020-11-01' = {
  name: firewallName
  location: location
  properties: {
    sku: {
      name: skuName
      tier: skuTier
    }
    ipConfigurations: concat([
      {
        name: publicIp.outputs.name
        properties: {
          subnet: {
            id: firewallSubnetId
          }
          publicIPAddress: {
            id: publicIp.outputs.id
          }
        }
      }
    ],firewallIPAdditionalIPAddrs)
    managementIpConfiguration: {
        name: managementpublicIp.outputs.name
        properties: {
          subnet: {
            id: firewallManagementSubnetId
          }
          publicIPAddress: {
            id: managementpublicIp.outputs.id
          }
        }
      }
    firewallPolicy: {
      id: firewallPolicyId
    }
  }
}

// Resource Lock
resource firewall_deleteLock 'Microsoft.Authorization/locks@2016-09-01' = if (enableResourceLock) {
  name: '${firewallName}-delete-lock'
  scope: firewall
  properties: {
    level: 'CanNotDelete'
    notes: 'Enabled as part of IaC Deployment'
  }
}

// Output Resource Name and Resource Id as a standard to allow module referencing.
output name string = firewall.name
output id string = firewall.id

