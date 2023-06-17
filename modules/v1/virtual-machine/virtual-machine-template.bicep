@description('Virtual machine name. Do not include numerical identifier.')
@maxLength(14)
param virtualMachineNameSuffix string

@description('Optional. Can be used to deploy multiple instances in a single deployment.')
@minValue(1)
param vmCount int = 1

@description('Optional. If doing multiple instances, you can change what number it starts from for naming purposes. Default is start from 01.')
@minValue(1)
param startIndex int = 1

@description('Virtual machine location.')
param location string = resourceGroup().location

@description('Virtual machine size, e.g. Standard_D2_v3, Standard_DS3, etc.')
param virtualMachineSize string

@description('Operating system disk type. E.g. If your VM is a standard size you must use a standard disk type.')
@allowed([
  'Standard_LRS'
  'StandardSSD_LRS'
  'Premium_LRS'
  'UltraSSD_LRS'
])
param osDiskType string

@description('Array of objects defining data disks, including diskType and size')
@metadata({
  note: 'Sample input'
  dataDisksDefinition: [
    {
      diskType: 'StandardSSD_LRS'
      diskSize: 64
      caching: 'none'
    } 
  ]
})
param dataDisksDefinition array

@description('Virtual machine Windows operating system.')
@allowed([
  '2016-Nano-Server'
  '2016-Datacenter-with-Containers'
  '2016-Datacenter'
  '2022-Datacenter'
  '2019-Datacenter'
  '2019-Datacenter-Core'
  '2019-Datacenter-Core-smalldisk'
  '2019-Datacenter-Core-with-Containers'
  '2019-Datacenter-Core-with-Containers-smalldisk'
  '2019-Datacenter-smalldisk'
  '2019-Datacenter-with-Containers'
  '2019-Datacenter-with-Containers-smalldisk'
])
param operatingSystem string = '2022-Datacenter'

@description('Enable if want to use Hybrid Benefit Licensing.')
param enableHybridBenefit bool = true

@description('Virtual machine local administrator username.')
param adminUsername string

@description('ResourceId of the Storage Account to send Diagnostic Logs')
param storageId string

@description('Local administrator password.')
@secure()
param adminPassword string

@description('Resource Id of Subnet to place VM into.')
param subnetId string

@description('If set to true, the availability zone will be picked based on instance ID.')
param useAvailabilityZones bool

@description('Image reference details')
param imageReference object = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: ''
  version: 'latest'
}

@description('Image reference details')
param plan object = {
  name: 'MicrosoftWindowsServer'
  publisher: 'WindowsServer'
  product: ''
}

@description('Resource Id of Log Analytics Workspace for VM Diagnostics')
param logAnalyticsId string

@description('True/False on whether to domain join VM as part of deployment.')
param enableDomainJoin bool

@description('FQDN of Domain to Join.')
param domainToJoin string =''

@description('OU to join VM into.')
param OUPath string = ''

@description('dataCollectionRuleAssociationName')
param dataCollectionRuleAssociationName string = 'VM-Health-Dcr-Association'

@description('healthDataCollectionRuleResourceId')
param healthDataCollectionRuleResourceId string 

@description('Username of the Domain Join process. Required when enableDomainJoin is true')
param domainJoinUser string = ''

@description('Time Zone setting for Virtual Machine')
param timeZone string = 'AUS Eastern Standard Time'

@description('Password for the user of the Domain Join process. Required when enableDomainJoin is true')
@secure()
param domainJoinPassword string = ''
 
@description('Object containing resource tags.')
param tags object = {}

@description('Enable a Can Not Delete Resource Lock.  Useful for production workloads.')
param enableResourceLock bool = false


resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = [for i in range(startIndex, vmCount): {
  name: '${virtualMachineNameSuffix}${format('{0:D2}',i)}-nic01'
  location: location
  tags: !empty(tags) ? tags : json('null')
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}]

resource vm 'Microsoft.Compute/virtualMachines@2021-04-01' = [for i in range(startIndex, vmCount): {
  name: '${virtualMachineNameSuffix}${format('{0:D2}',i)}'
  location: location
  tags: !empty(tags) ? tags : json('null')
  zones: useAvailabilityZones ? [     // Array with single value of either 1,2,3 based on VM number when using avail zones. Else empty array.
    (i % 3) + 1
  ] : [] 
  properties: {
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${virtualMachineNameSuffix}${format('{0:D2}',i)}-nic01')
        }
      ]
    }
    osProfile: {
      computerName: '${virtualMachineNameSuffix}${format('{0:D2}',i)}'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        timeZone: timeZone
      }
    }
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      imageReference: imageReference
      osDisk: {
        name: '${virtualMachineNameSuffix}${format('{0:D2}',i)}_osdisk'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      dataDisks: [for (item, j) in dataDisksDefinition: {
        name: '${virtualMachineNameSuffix}${format('{0:D2}',i)}_datadisk_${j}'
        diskSizeGB: item.diskSize
        lun: j
        caching: item.caching
        createOption: 'Empty'
        managedDisk: {
          storageAccountType: item.diskType
        }
      }]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri:storageId
      }
    }
    //licenseType: (enableHybridBenefit ? 'Windows_Server' : json('null'))
  }
  plan:plan
  dependsOn: [
    nic
  ]
}]

resource extension_monitoring 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = [for i in range(0, vmCount): {
  parent: vm[i]
  name: 'Microsoft.EnterpriseCloud.Monitoring'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: reference(logAnalyticsId, '2015-03-20').customerId
    }
    protectedSettings: {
      workspaceKey: listKeys(logAnalyticsId, '2015-03-20').primarySharedKey
    }
  }
}]

resource extension_depAgent 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = [for i in range(0, vmCount): {
  parent: vm[i]
  name: 'DependencyAgentWindows'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: 'DependencyAgentWindows'
    typeHandlerVersion: '9.5'
    autoUpgradeMinorVersion: true
  }
  dependsOn: [
    extension_monitoring
  ]
}]

resource extension_guesthealth 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = [for i in range(0, vmCount): {
  parent: vm[i]
  name: 'GuestHealthWindowsAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor.VirtualMachines.GuestHealth'
    type: 'GuestHealthWindowsAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
  }
  dependsOn: [
    extension_depAgent
    extension_monitoring
    extension_domainJoin
  ]
}]

resource extension_AzureMonitorWindowsAgent 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = [for i in range(0, vmCount): {
  parent: vm[i]
  name: 'AzureMonitorWindowsAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
  }
  dependsOn: [
    extension_guesthealth
  ]
}]

resource extension_domainJoin 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = [for i in range(0, vmCount): if (enableDomainJoin) {
  parent: vm[i]
  name: 'joindomain'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: domainToJoin
      OUPath: OUPath
      User: '${domainToJoin}\\${domainJoinUser}'
      Restart: 'true'
      Options: 3   // Join Domain and Create Computer Account
    }
    protectedSettings: {
      Password: domainJoinPassword
    }
  }
  dependsOn: [
    extension_depAgent
  ]
}]

resource dataCollectionRule 'Microsoft.Insights/dataCollectionRuleAssociations@2021-04-01' = [for i in range(0, vmCount): {
  name: '${virtualMachineNameSuffix}${format('{0:D2}',i)}-Microsoft.Insights-${dataCollectionRuleAssociationName}'
  scope: vm[i]
  properties: {
    dataCollectionRuleId:healthDataCollectionRuleResourceId
    description: 'Association of data collection rule for VM Insights Health.'
  }
  dependsOn:[
    extension_AzureMonitorWindowsAgent
    extension_guesthealth
  ]
}]


// Resource Lock
resource deleteLock 'Microsoft.Authorization/locks@2016-09-01'  = [for i in range(0, vmCount): if (enableResourceLock) {
  name: '${virtualMachineNameSuffix}${format('{0:D2}',i+startIndex)}-delete-lock'
  scope: vm[i]
  properties: {
    level: 'CanNotDelete'
    notes: 'Enabled as part of IaC Deployment'
  }
}]

output vmName string = vm[0].name
