// Private Endpoint for a Key Vault

@description('Name of the Resource for which to create the Private Endpoint')
param resourceName string

@description('Resource Id of the Resource for which to create the Private Endpoint')
param id string

@description('Location of the resource.')
param location string = resourceGroup().location

@description('Resource ID of the subnet that will host Private Endpoint.')
param subnetId string

@description('Select dataFactory to secure comms from Self Hosted Runtime. Select Portal for secure coms of authoring and monitoring the data factory.')
@allowed([
  'portal'
  'dataFactory'
])
param subResource string

@description('Resource Group of the Private DNS Zone Group to host Private Endpoint entry')
param dnsZoneResourceGroup string

@description('SubscriptionId of the Private DNS Zone Group to host Private Endpoint entry')
param dnsZoneSubscriptionId string

// Different subResource Types have different domains
var domainMapping = {
  portal: 'privatelink.adf.azure.com'
  dataFactory: 'privatelink.datafactory.azure.net'
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: '${resourceName}-pe'
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${resourceName}-plink'
        properties: {
          privateLinkServiceId: id
          groupIds: [
            subResource
          ]
        }
      }
    ]
  }
}

resource privateDNSZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  name: '${privateEndpoint.name}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: domainMapping[subResource]
        properties: {
          privateDnsZoneId: resourceId(dnsZoneSubscriptionId,dnsZoneResourceGroup,'Microsoft.Network/privateDnsZones',domainMapping[subResource])
        }
      }
    ]
  }
}

// Output Resource Name and Resource Id as a standard to allow module referencing.
output name string = privateEndpoint.name
output id string = privateEndpoint.id
