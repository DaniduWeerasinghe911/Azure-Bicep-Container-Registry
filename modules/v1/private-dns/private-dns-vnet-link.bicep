// Link set of Private DNS Zones to the provided VNET
// This should be deployed into the resource group that hosts the Private DNS Zones

@description('Array of Private DNS Zones to link')
param dnsZoneList array 

@description('Prefix to use in DNS Zone to VNET link')
param linkPrefix string

@description('ResourceId of Virtual Network')
param vnetId string 

@description('Is auto-registration of virtual machine records in the virtual network in the Private DNS zone enabled?')
param registrationEnabled bool = false

resource dnsZones 'Microsoft.Network/privateDnsZones@2020-06-01' existing = [for dnsZone in dnsZoneList: {
  name: dnsZone
}]

@description('Object containing resource tags.')
@metadata({
  Purpose: 'Sample Bicep Template'
  Environment: 'Development'
  Owner: 'sample.user@arinco.com.au'
})
param tags object = {}

resource dnsZonesLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for (dnsZone, i) in dnsZoneList: {
  name: '${linkPrefix}${dnsZone}'
  parent: dnsZones[i]
  location: 'global'
  tags: tags
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: registrationEnabled
  }
}]
