// VNET Peering Template between a Hub and a Spoke.  
// Configured to allow the Hub's VNA or VNET Gateway to forward traffic (i.e. support spoke to spoke comms)
// Default assumes there is a VNET Gateway / ExpressRoute in the hub, but this can be disabled if cloud native scenario.

@description('Name of the Hub VNET')
param hubVnetName string

@description('Resource Group of the Hub VNET')
param hubVnetResourceGroup string

@description('SubscriptionId of the Hub VNET')
param hubVnetSubscriptionId string

@description('Name of the Spoke VNET')
param spokeVnetName string

@description('Resource Group of the Spoke VNET')
param spokeVnetResourceGroup string

@description('SubscriptionId of the Spoke VNET')
param spokeVnetSubscriptionId string

@description('Set this to false if cloud native and no VNET Gateways for on-prem connectivity. ')
param hubHasGateway bool = true

var hubVnetId = resourceId(hubVnetSubscriptionId,hubVnetResourceGroup,'Microsoft.Network/virtualNetworks',hubVnetName)
var spokeVnetId = resourceId(spokeVnetSubscriptionId,spokeVnetResourceGroup,'Microsoft.Network/virtualNetworks',spokeVnetName)

// Peer from Hub to Spoke
module hub_spoke_peer './helper/vnet-peer.bicep' = {
  scope: resourceGroup(hubVnetSubscriptionId,hubVnetResourceGroup)
  name: 'deploy_hub_spoke_peer'
  params: {
    peerName: 'peer-hub-to-${spokeVnetName}'
    vnetName: hubVnetName
    remoteVnetId: spokeVnetId
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
  }
}

// Peer from Spoke to Hub
module spoke_hub_peer './helper/vnet-peer.bicep' = {
  scope: resourceGroup(spokeVnetSubscriptionId,spokeVnetResourceGroup)
  name: 'deploy_spoke_hub_peer'
  params: {
    peerName: 'peer-${spokeVnetName}-to-hub'
    vnetName: spokeVnetName
    remoteVnetId: hubVnetId
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: hubHasGateway
  }
}
