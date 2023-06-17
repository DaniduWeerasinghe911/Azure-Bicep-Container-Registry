@description('Resource Group Name')
param location string =  resourceGroup().location

@description('Type of the Private Endpoint')
param type string = 'azuremonitor'

@description('Subnet ID of the Private Endpoint Connection')
param subnetId string

@description('Ingetion Mode for the Link Scope')
param ingestionAccessMode string = 'Open'

@description('Query Mode for the Link Scope')
param queryAccessMode string = 'Open'

@description('Linked ResourceDetailes')
param linkedResources array

@description('Resource Group of the Private DNS Zone Group to host Private Endpoint entry')
param dnsZoneResourceGroup string

@description('Private Link Scope Name')
param linkScopeName string

@description('SubscriptionId of the Private DNS Zone Group to host Private Endpoint entry')
param dnsZoneSubscriptionId string

var resourceName = 'azure-monitor'


resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${resourceName}-pe'
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${resourceName}-${type}-plink'
        properties: {
          privateLinkServiceId: privateLinkScope.id
          groupIds: [
            type
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
        name: 'privatelink-monitor-azure-com'
        properties: {
          privateDnsZoneId: resourceId(dnsZoneSubscriptionId,dnsZoneResourceGroup,'Microsoft.Network/privateDnsZones','privatelink.monitor.azure.com')
        }
      }
      {
        name: 'privatelink-oms-opinsights-azure-com'
        properties: {
          privateDnsZoneId: resourceId(dnsZoneSubscriptionId,dnsZoneResourceGroup,'Microsoft.Network/privateDnsZones','privatelink.oms.opinsights.azure.com')
        }
      }
      {
        name: 'privatelink-ods-opinsights-azure-com'
        properties: {
          privateDnsZoneId: resourceId(dnsZoneSubscriptionId,dnsZoneResourceGroup,'Microsoft.Network/privateDnsZones','privatelink.ods.opinsights.azure.com')
        }
      }
      {
        name: 'privatelink-agentsvc-azure-automation-net'
        properties: {
          privateDnsZoneId: resourceId(dnsZoneSubscriptionId,dnsZoneResourceGroup,'Microsoft.Network/privateDnsZones','privatelink.agentsvc.azure-automation.net')
        }
      }
      {
        name: 'privatelink-blob-core-windows-net'
        properties: {
          privateDnsZoneId: resourceId(dnsZoneSubscriptionId,dnsZoneResourceGroup,'Microsoft.Network/privateDnsZones','privatelink.blob.core.windows.net')
        }
      }
    ]
  }
}

resource privateLinkScope 'microsoft.insights/privateLinkScopes@2021-07-01-preview' = {
  name: linkScopeName
  location: 'global'
  properties: {
    accessModeSettings: {
      exclusions: [ 
      ]
      ingestionAccessMode: ingestionAccessMode
      queryAccessMode: queryAccessMode
    }
  }
}

resource linkResources 'Microsoft.Insights/privateLinkScopes/scopedResources@2021-07-01-preview' = [for linkedResource in linkedResources:{
  name: 'scoped-${linkedResource.name}'
  parent: privateLinkScope
  properties: {
    linkedResourceId: linkedResource.id
  }
  dependsOn: [
    privateDNSZoneGroup
  ]
}]



output linkScopeName string = linkScopeName
