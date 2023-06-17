@description('Target geographical location')
param location string

@description('Name of Expressroute Circuit')
param erName string

@description('Expressroute Circuit bandwidth in Mbps')
param erBandwidth int

@description('Expressroute peering location (e.g. Sydney2)')
param peeringLocation string

@description('Allow classic operations')
param allowClassicOperations bool

@description('Expressroute provider name (e.g. Megaport)')
param serviceProviderName string

@description('ExpressRoute peering type (e.g. AzurePrivatePeering)')
param expressRoutePeeringType string

@description('Primary BGP peering range vor ExpressRoute')
param expressRoutePrimaryPeering string

@description('Secondary BGP peering range vor ExpressRoute')
param expressRouteSecondaryPeering string

@description('VLAN for BGP peering over ExpressRoute')
param expressRoutePeeringVLAN int

@description('ASN for BGP peering over ExpressRoute')
param expressRoutePeeringASN int

@description('Expressroute peering state (Enabled or Disabled)')
param peeringState string

@allowed([
  'MeteredData'
  'UnlimitedData'
])
param erFamily string

@allowed([
  'Basic'
  'Local'
  'Premium'
  'Standard'
])
param erTier string

resource expressRoute 'Microsoft.Network/expressRouteCircuits@2020-11-01' = {
  name: erName
  location: location
  sku:{
    family: erFamily
    tier: erTier
    name: '${erTier}_${erFamily}'
  }
  properties:{
    peerings: [
      {
        name: expressRoutePeeringType
        properties: {
          peerASN: expressRoutePeeringASN
          vlanId: expressRoutePeeringVLAN
          primaryPeerAddressPrefix: expressRoutePrimaryPeering
          secondaryPeerAddressPrefix:expressRouteSecondaryPeering
          peeringType: expressRoutePeeringType
          state: peeringState
        }

      }
    ]
    serviceProviderProperties:{
      bandwidthInMbps: erBandwidth
        peeringLocation: peeringLocation
      serviceProviderName: serviceProviderName
    }
    allowClassicOperations: allowClassicOperations
  }
}

output expressRouteResourceID string = expressRoute.id
