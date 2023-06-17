// Module for creating Netowrk Watcher

@description('Location in which resources will be created')
param location string = resourceGroup().location

@description('Network Watcher name')
param nwName string

@description('Object containing resource tags.')
param tags object = {}

@description('Enable a Can Not Delete Resource Lock.  Useful for production workloads.')
param enableResourceLock bool = false

resource network_watcher 'Microsoft.Network/networkWatchers@2021-02-01' = {
  name: nwName
  location: location
  tags: tags
  properties: {}
}

// Resource Lock
resource deleteLock 'Microsoft.Authorization/locks@2016-09-01' = if (enableResourceLock) {
  name: '${nwName}-delete-lock'
  scope: network_watcher
  properties: {
    level: 'CanNotDelete'
    notes: 'Enabled as part of IaC Deployment'
  }
}
