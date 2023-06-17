@description('Name of the Storage account for configuration data')
param dscStorageAccount string

@description('Name of the Storage account continer for configuration data')
param dscStorageAccountContainer string

@description('Define the number of AVD instances Required')
param AVDnumberOfInstances int

@description('Define the number of Current instances Required')
param currentInstances int = 0

@description('Location for all standard resources to be deployed into.')
param location string = 'australiaEast'

@description('Prefix Value for the Virtual Machines')
param vmPrefix string

@description('Disk Type for the Virtual Machines')
param vmDiskType string = 'Standard_LRS'

@description('Virtual Machine Type')
param vmSize string

@description('Virtual Machin Image Verions')
param vmImageVerion string = ''

@description('Local Administrator User Name')
param administratorAccountUserName string

@description('Local Administrator Password')
@secure()
param administratorAccountPassword string

@description('Subnet ID')
param subnetID string

@description('RegistrationToken for the AVD environment')
param avdRegToken string

@description('FQDN of Domain to Join.')
param domainToJoin string

// @description('dataCollectionRuleAssociationName')
// param dataCollectionRuleAssociationName string = 'VM-Health-Dcr-Association'

// @description('healthDataCollectionRuleResourceId')
// param healthDataCollectionRuleResourceId string 

@description('OU to join VM into.')
param ouPath string = ''

@description('FSLogix Profile containter path for the virtual machine')
param azureUserProfileShare string = '\\\\dckloudstandard.file.core.windows.net\\profiles'

@description('Username of the Domain Join process. Required when enableDomainJoin is true')
param domainJoinUser string = 'admin.dancha'

@description('Time Zone setting for Virtual Machine')
param timeZone string = 'AUS Eastern Standard Time'

@description('Password for the user of the Domain Join process. Required when enableDomainJoin is true')
@secure()
param domainJoinPassword string = 'Pass@123456789'

@description('Resource Id of Log Analytics Workspace for VM Diagnostics')
param logAnalyticsId string = '/subscriptions/6da6ad04-e536-4124-a437-c62b91ca3cff/resourceGroups/rg-monitoring-dckloud/providers/Microsoft.OperationalInsights/workspaces/law-monitoring-dckloud'

@description('AVD VM Image reference details')
param imageReference object = {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'Windows-10'
        sku: '21h1-evd'
        version: 'latest'
        id:''
}

//Defining Variables for the Deployment
var avSetSKU = 'Aligned'
var existingDomainUserName = first(split(administratorAccountUserName, '@'))
var networkAdapterPostfix = '-nic'
var configFilePath = 'https://${dscStorageAccount}.blob.core.windows.net/${dscStorageAccountContainer}/configuration.zip'


var vmPrefixUpdated = '${vmPrefix}${vmImageVerion}'

resource nic 'Microsoft.Network/networkInterfaces@2020-06-01' = [for i in range(0, AVDnumberOfInstances): {
  name: '${vmPrefixUpdated}-${i + currentInstances}${networkAdapterPostfix}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetID
          }
        }
      }
    ]
  }
}]

resource availabilitySet 'Microsoft.Compute/availabilitySets@2020-12-01' = {
  name: '${vmPrefixUpdated}-AV'
  location: location
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 10
  }
  sku: {
    name: avSetSKU
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2020-06-01' = [for i in range(0, AVDnumberOfInstances): {
  name: '${vmPrefixUpdated}-${i + currentInstances}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    licenseType: 'Windows_Client'
    hardwareProfile: {
      vmSize: vmSize
    }
    availabilitySet: {
      id: resourceId('Microsoft.Compute/availabilitySets', '${vmPrefixUpdated}-AV')
    }
    osProfile: {
      computerName: '${vmPrefixUpdated}-${i + currentInstances}'
      adminUsername: existingDomainUserName
      adminPassword: administratorAccountPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        timeZone: timeZone
      }
    }
    storageProfile: {
      osDisk: {
        name: '${vmPrefixUpdated}-${i + currentInstances}-OS'
        managedDisk: {
          storageAccountType: vmDiskType
        }
        osType: 'Windows'
        createOption: 'FromImage'
      }
      imageReference: {
        publisher: empty(imageReference.publisher) ? json('null') : imageReference.publisher
        offer: empty(imageReference.offer) ? json('null') : imageReference.offer
        sku: empty(imageReference.sku) ? json('null') : imageReference.sku
        version: empty(imageReference.version) ? json('null') : imageReference.version
        id:empty(imageReference.id) ? json('null') : imageReference.id
      }
      dataDisks: []
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${vmPrefixUpdated}-${i + currentInstances}${networkAdapterPostfix}')
        }
      ]
    }
  }
  dependsOn: [
    availabilitySet
    nic[i]
  ]
}]

resource joindomain 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = [for i in range(0, AVDnumberOfInstances): {
  name: '${vmPrefixUpdated}-${i + currentInstances}/joindomain'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: domainToJoin
      OUPath: ouPath
      User: '${domainToJoin}\\${domainJoinUser}'
      Restart: 'true'
      Options: 3 // Join Domain and Create Computer Account
    }
    protectedSettings: {
      Password: domainJoinPassword
    }
  }
  dependsOn: [
    vm[i]
  ]
}]

resource dscextension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = [for i in range(0, AVDnumberOfInstances): {
  name: '${vmPrefixUpdated}-${i + currentInstances}/dscextension'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.73'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: configFilePath
      configurationFunction: 'Configuration.ps1\\WVDSoftwareInstall'
      properties: {
        'azureUserProfileShare': azureUserProfileShare
        'wvdRegistrationToken': avdRegToken
        'installCcmClient': false
      }
    }
  }
  dependsOn: [
    vm[i]
    joindomain[i]
  ]
}]

resource extension_monitoring 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = [for i in range(0, AVDnumberOfInstances): {
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

resource extension_depAgent 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = [for i in range(0, AVDnumberOfInstances): {
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
    //extension_monitoring
  ]
}]

resource extension_guesthealth 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = [for i in range(0, AVDnumberOfInstances): {
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
  ]
}]

resource extension_AzureMonitorWindowsAgent 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = [for i in range(0, AVDnumberOfInstances): {
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

// resource dataCollectionRule 'Microsoft.Insights/dataCollectionRuleAssociations@2021-04-01' = [for i in range(0, AVDnumberOfInstances): {
//   name: '${vmPrefixUpdated}${format('{0:D2}',i)}-Microsoft.Insights-${dataCollectionRuleAssociationName}'
//   scope: vm[i]
//   properties: {
//     dataCollectionRuleId:healthDataCollectionRuleResourceId
//     description: 'Association of data collection rule for VM Insights Health.'
//   }
//   dependsOn:[
//     extension_AzureMonitorWindowsAgent
//     extension_guesthealth
//   ]
// }]
