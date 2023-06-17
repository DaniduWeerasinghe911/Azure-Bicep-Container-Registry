/*
  Purpose: 
  This Bicep file has been created to specifically capture the infrastructure requirements for a Azure DevOps Windows Agent
  deployed into a VM Scale Set.  Refer to https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/scale-set-agents?view=azure-devops

  It assumes you have created a Managed Image that contains all the toolsets you need.  

  TO DO:  Make this aligned with the other modules
*/

@description('The resource name of the VM Scale Set.')
param vmssName string

@description('The prefix used for each VM in the scale set.')
param vmNamePrefix string

@description('Location of the VM in the scale set.')
param location string = resourceGroup().location

@description('The VM Sku to use for each node in scale set.')
param vmSku string

@secure()
@description('Local admin username')
param adminUsername string

@secure()
@description('Local admin password')
param adminPassword string

@description('Resource Group of VNET')
param vnetResourceGroup string

@description('VNET Name')
param vnetName string

@description('Subnet Name')
param subnetName string

@description('Resource ID of Managed Image')
param managedImageId string

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2020-12-01' = {
  name: vmssName
  location: location
  tags: {}
  sku: {
    name: vmSku
    tier: 'Standard'
    capacity: 1       // DevOps will scale and manage this
  }
  properties: {
    upgradePolicy: {
      mode: 'Manual'  // Required for DevOps Agent
    }
    virtualMachineProfile: {
      osProfile: {
        computerNamePrefix: vmNamePrefix
        adminUsername: adminUsername
        adminPassword: adminPassword
      }
      storageProfile: {
        imageReference: {
          id: managedImageId
        }    
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadOnly'
        }

      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: '${vmNamePrefix}-nic01'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfig1'
                  properties: {
                    primary: true
                    subnet: {
                      id: resourceId(vnetResourceGroup,'Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
                    }
                  }
                }
              ]
            }
          }
        ]
      }
    }
    overprovision: false // Required for DevOps agent
  }
}
