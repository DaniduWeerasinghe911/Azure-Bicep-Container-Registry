// Private Endpoint for a Service Bus

@description('Name of the Resource for which to create the Private Endpoint')
param resourceName string

@description('Location of the resource.')
param location string = resourceGroup().location

@description('Resource ID of the subnet that will host Private Endpoint.')
param subnetId string

@description('Resource Group of the Private DNS Zone Group to host Private Endpoint entry')
param dnsZoneResourceGroup string

@description('Subscription Id of the Private DNS Zone Group to host Private Endpoint entry')
param dnsZoneSubscription string

@description('Resource Id of the Service Bus Namespace that the Private Endpoint is being created for')
param privateLinkServiceId string

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
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
          privateLinkServiceId: privateLinkServiceId
          groupIds: [
            'namespace'
          ]
        }
      }
    ]
  }
}

resource privateDNSZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  name: '${privateEndpoint.name}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink.servicebus.windows.net'
        properties: {
          privateDnsZoneId: resourceId(dnsZoneSubscription,dnsZoneResourceGroup,'Microsoft.Network/privateDnsZones','privatelink.servicebus.windows.net')
        }
      }
    ]
  }
}

// Output Resource Name and Resource Id as a standard to allow module referencing.
output name string = privateEndpoint.name
output id string = privateEndpoint.id
