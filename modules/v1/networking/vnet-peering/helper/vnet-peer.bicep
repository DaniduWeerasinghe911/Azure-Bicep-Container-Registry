// Helper Bicep Module to wrap around VNET Peer so that we can use it as a module for the purposes of scoping

@description('Name of peering connection')
param peerName string

@description('Grant access to peer virtual network resources.')
param allowVirtualNetworkAccess bool

@description('Allow traffic not orginating from inside the peer network')
param allowForwardedTraffic bool

@description('Allows the virtual network to a peer network gateway')
param allowGatewayTransit bool

@description('Uses a peers virtual network gateway')
param useRemoteGateways bool

@description('Name of virtual network to peer')
param vnetName string

@description('ID of remote virtual network to peer')
param remoteVnetId string

resource spokePeer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  name: '${vnetName}/${peerName}'
  properties: {
    allowVirtualNetworkAccess: allowVirtualNetworkAccess
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
    remoteVirtualNetwork: {
      id: remoteVnetId
    }
  }
}
