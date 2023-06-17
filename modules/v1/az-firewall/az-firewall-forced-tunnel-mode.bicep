// Azure Firewall that is deployed in Forced Tunnel Mode.
// Only used this if you have an environment that uses ExpressRoute with forced tunnelling (i.e. default route points to onprem)

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

@description('The Id of the management subnet.')
param managementSubnetId string

@description('The Id of the firewall policy.')
param firewallPolicyId string

@description('Location of the resource.')
param location string = resourceGroup().location

@description('Object containing resource tags.')
param tags object = {}

@description('Enable a Can Not Delete Resource Lock.  Useful for production workloads.')
param enableResourceLock bool = false

@description('Object containing diagnostics settings. If not provided diagnostics will not be set.')
param diagSettings object = {}

// Resource Names
param inboundPublicIpName string = '${firewallName}-in-pip'
param outboundPublicIpName string = '${firewallName}-out-pip'

// Inbound Public IP Resource
module inboundPublicIp '../networking/public-ip/public-ip.bicep' = {
  name: 'deploy_inbound_public_ip'
  params:{
    publicIpName: inboundPublicIpName
    location: location
    tags: tags
    sku: 'Standard'
    publicIPAllocationMethod: 'Static'
    diagSettings: diagSettings
    enableResourceLock: enableResourceLock
  }
}

// Outbound Public IP Resource
module outboundPublicIp '../networking/public-ip/public-ip.bicep' = {
  name: 'deploy_outbound_public_ip'
  params:{
    publicIpName: outboundPublicIpName
    location: location
    tags: tags
    sku: 'Standard'
    publicIPAllocationMethod: 'Static'
    diagSettings: diagSettings
    enableResourceLock: enableResourceLock
  }
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
    ipConfigurations: [
      {
        name: inboundPublicIpName
        properties: {
          subnet: {
            id: firewallSubnetId
          }
          publicIPAddress: {
            id: inboundPublicIp.outputs.id
          }
        }
      }
    ]
    managementIpConfiguration: {
      name: outboundPublicIpName
      properties: {
        subnet: {
          id: managementSubnetId
        }
        publicIPAddress: {
          id: outboundPublicIp.outputs.id
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

