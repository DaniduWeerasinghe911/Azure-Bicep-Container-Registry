@description('Location of resources.')
param location string

@description('NSG Name')
param nsgName string

@description('NSG Resource ID')
param nsgId string

@description('Diagnostic Storage ID')
param diagStorageID string

var loc = replace(location,' ','')

resource sharedNsgFlowLogs 'Microsoft.Network/networkWatchers/flowLogs@2020-08-01' = {
  name: 'nw-${loc}/NetworkWatcher_${nsgName}_FlowLogs'
  location: location
  properties: {
    targetResourceId: nsgId
    storageId: diagStorageID
    enabled: true
    retentionPolicy: {
      days: 2
      enabled: true
    }
    format: {
      type: 'JSON'
      version: 2
    }
  }
}
