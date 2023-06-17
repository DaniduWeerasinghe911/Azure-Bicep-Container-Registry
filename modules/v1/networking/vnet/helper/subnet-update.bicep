/*  Module that can be used to modify and update an existing subnet's properties
    Use this module to:
      - Attach an NSG
      - Configure Service Endpoints and Service Endpoint Policies
      - Enable/Disable PrivateEndpoint and PrivateLinkService Network Policies
      - Configure a Subnet Delegation

    Will reuse existing subnet properties where an equivalent param is not provided
    Assumes you can't (or shouldn't) change addressPrefix of an existing subnet
    But because ARM is the worst, existing subnet properties don't return NSG, Route Table, ServiceEndpoints or ServiceEndpointPolicies
    so if these are existing you need to provide these seperately to ensure they don't get changed as part of this module call
*/

@description('ExistingResource Id of Subnet to modify')
param subnetId string

@description('Existing subnet Properties object.')
param subnetProperties object

@description('Resource Id of new or existing Network Security Group. Leave blank if none.')
param nsgId string = ''

@description('Resource Id of new or existing Route Table. Leave blank if none.')
param routeTableId string = ''

@description('Array of Service Endpoints to add. Leave empty if none.')
param serviceEndpoints array = []

@description('Array of Service Endpoints Policy Objects to add. Leave empty if none.')
param serviceEndpointPolicies array = []

@description('Whether to enable/disable Network Policies to support Private Endpoints. Leave empty to not change.')
param privateEndpointNetworkPolicies string = ''

@description('Whether to enable/disable Network Policies to support Private Link Service. Leave blank to not change.')
param privateLinkServiceNetworkPolicies string = ''

@description('Service Name for Delegation. Leave blank to not change.')
param delegationServiceName string = ''

// Extract out relevant components
var subnetName = split(subnetId,'/')[10]
var vnetName = split(subnetId,'/')[8]

// Get Existing VNET Object for parent scoping
resource vnet 'Microsoft.Network/virtualNetworks@2020-07-01' existing = {
  name: vnetName
}

resource modify_subnet 'Microsoft.Network/virtualNetworks/subnets@2020-07-01' = {
  parent: vnet
  name: subnetName
  properties: {
    addressPrefix: subnetProperties.addressPrefix
    networkSecurityGroup: empty(nsgId) ? json('null') : {
      id: nsgId
    }
    routeTable: empty(routeTableId) ? json('null') : {
      id: routeTableId
    }
    privateEndpointNetworkPolicies: empty(privateEndpointNetworkPolicies) ? subnetProperties.privateEndpointNetworkPolicies : privateEndpointNetworkPolicies
    privateLinkServiceNetworkPolicies:  empty(privateLinkServiceNetworkPolicies) ? subnetProperties.privateLinkServiceNetworkPolicies : privateLinkServiceNetworkPolicies
    serviceEndpoints: empty(serviceEndpoints) ? [] : serviceEndpoints
    serviceEndpointPolicies: empty(serviceEndpointPolicies) ? [] : serviceEndpointPolicies
    delegations:  empty(delegationServiceName) ? subnetProperties.delegations : [
      {
        name: 'delegation'
        properties: {
          serviceName: delegationServiceName
        }
      }
    ] 
  }
}
