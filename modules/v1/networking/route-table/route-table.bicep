@description('The name of the route table to deploy')
param routeTableName string

@description('Location for resources to be created')
param location string = resourceGroup().location

@description('Enable/Disable BGP Route Propagation')
param disableBgpRoutePropagation bool

@description('The routes that will be attached to the route table')
@metadata({
  note: 'Sample Input'
  routes: [
    {
      name: 'default-to-hub-nva'
      properties: {
        addressPrefix: '0.0.0.0/0'
        nextHopType: 'VirtualAppliance'
        nextHopIpAddress: '10.0.0.4'
      }
    }
    {
      name: 'kms-to-internet'
      properties: {
        addressPrefix: '23.102.135.246/32'
        nextHopType: 'Internet'
      }
    }
  ]
})
param routes array

@description('Enable a Can Not Delete Resource Lock. Useful for production workloads.')
param enableResourceLock bool

// Resource Definition
resource routeTable 'Microsoft.Network/routeTables@2019-11-01' = {
  name: routeTableName
  location: location
  properties: {
    disableBgpRoutePropagation: disableBgpRoutePropagation
    routes: routes
  }
}

// Resource Lock
resource deleteLock 'Microsoft.Authorization/locks@2016-09-01' = if (enableResourceLock) {
  name: '${routeTableName}-delete-lock'
  scope: routeTable
  properties: {
    level: 'CanNotDelete'
    notes: 'Enabled as part of IaC Deployment'
  }
}

// Output Resource Name and Resource Id as a standard to allow module referencing.
output name string = routeTable.name
output id string = routeTable.id
