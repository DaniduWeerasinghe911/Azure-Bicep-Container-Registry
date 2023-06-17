@description('Expressroute connection name')
param erConName string

@description('Target geographical location')
param location string

@description('Resource Id of target vNet gateway for Expressroute connection')
param vnetGwId string

@description('Connection priority')
param connectionPriority int

@description('ExpressRoute Resource ID')
param expressRouteResourceID string

resource expressRouteGatewayConnection 'Microsoft.Network/connections@2020-11-01' = {
  name: erConName
  location: location
  properties: {
    virtualNetworkGateway1: {
      id: vnetGwId
      properties:{}
    }
    peer: {
      id: expressRouteResourceID
    }
    connectionType: 'ExpressRoute'
    routingWeight: connectionPriority
  }
}

