// Contains network related preqreqs for Data bricks.
// This has been carved out because it looks like you can't redpeloy the standard NSGs once Databricks takes delegation ownership of the subnet

@description('The name of the Databricks Workspace.')
param workspaceName string

@description('Name of NSG with Databricks rules to assocaite to subnets')
param nsgName string = '${workspaceName}-nsg'

@description('Resource Id of VNET for which to integrate with. Assumes subnets are already created.')
param vnetId string 

@description('Name of existing Subnet for container, aka private subnet')
param privateSubnetName string 

@description('Name of existing Subnet for host, aka public subnet')
param publicSubnetName string 

@description('Resource Id of existing Route Table to assign to Subnets.  Leave blank if none.')
param routeTableId string = ''

@description('Object containing resource tags.')
param tags object = {}

@description('Enable a Can Not Delete Resource Lock.  Useful for production workloads.')
param enableResourceLock bool = false

@description('Object containing diagnostics settings. If not provided diagnostics will not be set.')
param diagSettings object = {}

// Databricks NSG Resource Definition
module nsg '../../../v1/networking/nsg/nsg.bicep' = {
  name: 'deploy_databricks_nsg'
  params: {
    nsgName: nsgName
    securityRules: [
      {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-worker-inbound'
        properties: {
          description: 'Required for worker nodes communication within a cluster.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-databricks-webapp'
        properties: {
          description: 'Required for workers communication with Databricks Webapp.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureDatabricks'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-sql'
        properties: {
          description: 'Required for workers communication with Azure SQL services.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3306'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Sql'
          access: 'Allow'
          priority: 101
          direction: 'Outbound'
        }
      }
      {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-storage'
        properties: {
          description: 'Required for workers communication with Azure Storage services.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Storage'
          access: 'Allow'
          priority: 102
          direction: 'Outbound'
        }
      }
      {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-worker-outbound'
        properties: {
          description: 'Required for worker nodes communication within a cluster.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 103
          direction: 'Outbound'
        }
      }
      {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-eventhub'
        properties: {
          description: 'Required for worker communication with Azure Eventhub services.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '9093'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'EventHub'
          access: 'Allow'
          priority: 104
          direction: 'Outbound'
        }
      }
    ]
    tags: tags
    diagSettings: diagSettings
    enableResourceLock: enableResourceLock
  }
}

// Get details of existing subnets
var subnetSubId = split(vnetId,'/')[2]
var subnetRgName = split(vnetId,'/')[4]
var vnetName = split(vnetId,'/')[8]

resource publicSubnet_resource 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  scope: resourceGroup(subnetSubId, subnetRgName)
  name: '${vnetName}/${publicSubnetName}'
}

resource privateSubnet_resource 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  scope: resourceGroup(subnetSubId, subnetRgName)
  name: '${vnetName}/${privateSubnetName}'
}

// Delegate Databricks Service to Subnets and attach the NSG
module delegate_publicSubnet '../../../v1/networking/vnet/helper/subnet-update.bicep' = {
  name: 'delegate_publicSubnet'
  scope: resourceGroup(subnetSubId, subnetRgName)
  params: {
    subnetId: publicSubnet_resource.id
    subnetProperties: publicSubnet_resource.properties
    nsgId: nsg.outputs.id
    delegationServiceName: 'Microsoft.Databricks/workspaces'
    routeTableId: routeTableId
  }
  dependsOn: [
  ]
}

module delegate_privateSubnet '../../../v1/networking/vnet/helper/subnet-update.bicep' = {
  name: 'delegate_privateSubnet'
  scope: resourceGroup(subnetSubId, subnetRgName)
  params: {
    subnetId: privateSubnet_resource.id
    subnetProperties: privateSubnet_resource.properties
    nsgId: nsg.outputs.id
    delegationServiceName: 'Microsoft.Databricks/workspaces'
    routeTableId: routeTableId
  }
  dependsOn: [
    delegate_publicSubnet
  ]
}
