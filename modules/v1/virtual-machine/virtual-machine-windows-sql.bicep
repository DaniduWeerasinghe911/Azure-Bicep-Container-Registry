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
param osDiskType string = 'Premium_LRS'

@description('Array of objects defining data disks, including diskType and size')
@metadata({
  note: 'Sample input'
  dataDisksDefinition: [
    {
      diskSizeGB: 64
      createOption: 'empty'
    }
  ]
})
param dataDisksDefinition array

@description('Virtual machine Windows operating system.')
@allowed([
  'enterprise'
  'Standard'
])
param operatingSystem string = 'Standard'

@description('Enable if want to use Hybrid Benefit Licensing.')
param enableHybridBenefit bool = true

@description('Virtual machine local administrator username.')
param adminUsername string

@description('Local administrator password.')
@secure()
param adminPassword string

@description('(Optional) Create SQL Server sysadmin login user name')
param sqlAuthUpdateUserName string = ''

@description('(Optional) Create SQL Server sysadmin login password')
param sqlAuthUpdatePassword string = ''

@description('ResourceId of the Storage Account to send Diagnostic Logs')
param storageId string

@description('Resource Id of Subnet to place VM into.')
param subnetId string

@description('If set to true, the availability zone will be picked based on instance ID.')
param useAvailabilityZones bool = false

@description('Resource Id of Log Analytics Workspace for VM Diagnostics')
param logAnalyticsId string

@description('True/False on whether to domain join VM as part of deployment.')
param enableDomainJoin bool = true

@description('FQDN of Domain to Join.')
param domainToJoin string

@description('OU to join VM into.')
param OUPath string

@description('Username of the Domain Join process. Required when enableDomainJoin is true')
param domainJoinUser string

@description('Time Zone setting for Virtual Machine')
param timeZone string = 'AUS Eastern Standard Time'

@description('Password for the user of the Domain Join process. Required when enableDomainJoin is true')
@secure()
param domainJoinPassword string

@description('Object containing resource tags.')
param tags object = {}

@description('Object containing resource tags.')
param diskConfigurationType string = 'NEW'

@description('StorageWorkloadType')
param StorageWorkloadType string = 'General'

@description('Path for SQL Data files. Please choose drive letter from F to Z, and other drives from A to E are reserved for system')
param dataPath string = 'G:\\SQLData'

@description('Path for SQL Log files. Please choose drive letter from F to Z and different than the one used for SQL data. Drive letter from A to E are reserved for system')
param logPath string = 'L:\\SQLLog'

///////////////////////////////////////

@description('Select the version of SQL Server Image type')
@allowed([
  'SQL2017-WS2016'
  'SQL2016SP2-WS2016'
  'SQL2019-WS2019'
  ''
])
param sqlServerImageType string = 'SQL2019-WS2019'

/*@description('SQL Server Image SKU')
@allowed([
  'Developer'
  'Enterprise'
])
param sqlImageSku string = 'Enterprise'*/

@description('SQL server connectivity option')
@allowed([
  'LOCAL'
  'PRIVATE'
  'PUBLIC'
])
param sqlConnectivityType string = 'PRIVATE'

@description('SQL server port')
param sqlPortNumber int = 1433

@description('SQL server workload type')
@allowed([
  'DW'
  'GENERAL'
  'OLTP'
])
param sqlStorageWorkloadType string = 'GENERAL'

@description('SQL server license type')
@allowed([
  'AHUB'
  'PAYG'
  'DR'
])
param sqlServerLicenseType string = 'AHUB'

@description('Enable or disable EKM provider for Azure Key Vault.')
param enableAkvEkm bool = false

@description('Azure Key Vault URL (only required when enableAkvEkm is set to true).')
param sqlAkvUrl string = ''

@description('name of the sql credential created for Azure Key Vault EKM provider (only required when enableAkvEkm is set to true).')
param sqlAkvCredentialName string = 'sysadmin_ekm_cred'

@description('Azure service principal Application Id for accessing the EKM Azure Key Vault (only required when enableAkvEkm is set to true).')
param sqlAkvPrincipalName string

@description('Azure service principal secret for accessing the EKM Azure Key Vault (only required when enableAkvEkm is set to true).')
@secure()
param sqlAkvPrincipalSecret string

@description('Logical Disk Numbers (LUN) for SQL data disks.')
param dataDisksLUNs array

@description('Logical Disk Numbers (LUN) for SQL log disks.')
param logDisksLUNs array

@description('Default path for SQL Temp DB files.')
param tempDBPath string = 'H:\\SQLTemp'

@description('Logical Disk Numbers (LUN) for SQL Temp DB disks.')
param tempDBDisksLUNs array

@description('Enable or disable R services (SQL 2016 onwards).')
param rServicesEnabled bool = false

@description('Name of the SQL Always-On cluster name. Only required when deploying a SQL cluster.')
param sqlVmGroupName string = ''

@description('password for the cluster bootstrap account. Only required when deploying a SQL cluster.')
@secure()
param sqlClusterBootstrapAccountPassword string = ''

@description('password for the cluster operator account. Only required when deploying a SQL cluster.')
@secure()
param sqlClusterOperatorAccountPassword string = ''

@description('password for the sql service account. Only required when deploying a SQL cluster.')
@secure()
param sqlServiceAccountPassword string = ''

@description('Enable or disable SQL server auto backup.')
param enableAutoBackup bool

@description('Enable or disable encryption for SQL server auto backup.')
param enableAutoBackupEncryption bool

@description('SQL backup retention period. 1-30 days')
param autoBackupRetentionPeriod int = 30

@description('name of the storage account used for SQL auto backup')
param autoBackupStorageAccountName string = ''

@description('Resource group for the storage account used for SQL Auto Backup')
param autoBackupStorageAccountResourceGroup string = resourceGroup().name

@description('password for SQL backup encryption. Required when \'enableAutoBackupEncryption\' is set to \'true\'.')
param autoBackupEncryptionPassword string = ''

@description('Include or exclude system databases from SQL server auto backup.')
param autoBackupSystemDbs bool = true

@description('SQL server auto backup schedule type - \'Manual\' or \'Automated\'.')
@allowed([
  'Manual'
  'Automated'
])
param autoBackupScheduleType string = 'Automated'

@description('SQL server auto backup full backup frequency - \'Daily\' or \'Weekly\'. Required parameter when \'autoBackupScheduleType\' is set to \'Manual\'. Default value is \'Daily\'.')
@allowed([
  'Daily'
  'Weekly'
])
param autoBackupFullBackupFrequency string = 'Daily'

@description('SQL server auto backup full backup start time - 0-23 hours. Required parameter when \'autoBackupScheduleType\' is set to \'Manual\'. Default value is 23.')
param autoBackupFullBackupStartTime int = 23

@description('SQL server auto backup full backup allowed duration - 1-23 hours. Required parameter when \'autoBackupScheduleType\' is set to \'Manual\'. Default value is 2.')
param autoBackupFullBackupWindowHours int = 2

@description('SQL server auto backup log backup frequency - 5-60 minutes. Required parameter when \'autoBackupScheduleType\' is set to \'Manual\'. Default value is 60.')
param autoBackupLogBackupFrequency int = 60

@description('dataCollectionRuleAssociationName')
param dataCollectionRuleAssociationName string = 'VM-Health-Dcr-Association'

@description('healthDataCollectionRuleResourceId')
param healthDataCollectionRuleResourceId string 


//////////////////////////////////////

@description('Enable a Can Not Delete Resource Lock.  Useful for production workloads.')
param enableResourceLock bool = false

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = [for i in range(startIndex, vmCount): {
  name: '${virtualMachineNameSuffix}${format('{0:D2}', i)}-nic01'
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

resource dataDisk 'Microsoft.Compute/disks@2020-12-01' = [for (item, j) in dataDisksDefinition: {
  name: '${virtualMachineNameSuffix}${format('{0:D2}', 1)}_datadisk_${j}'
  location: location
  properties: {
    creationData: {
      createOption: item.createOption
    }
    diskSizeGB: item.diskSizeGB
  }
  sku: {
    name: osDiskType
  }
}]

resource vm 'Microsoft.Compute/virtualMachines@2021-04-01' = [for i in range(startIndex, vmCount): {
  name: '${virtualMachineNameSuffix}${format('{0:D2}', i)}'
  location: location
  tags: !empty(tags) ? tags : json('null')
  zones: useAvailabilityZones ? [
    // Array with single value of either 1,2,3 based on VM number when using avail zones. Else empty array.
    (i % 3) + 1
  ] : []
  properties: {
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${virtualMachineNameSuffix}${format('{0:D2}', i)}-nic01')
        }
      ]
    }
    osProfile: {
      computerName: '${virtualMachineNameSuffix}${format('{0:D2}', i)}'
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
      imageReference: {
        publisher: 'microsoftsqlserver'
        offer: 'sql2019-ws2022'
        sku: operatingSystem
        version: 'latest'
      }
      osDisk: {
        name: '${virtualMachineNameSuffix}${format('{0:D2}', i)}_osdisk'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      dataDisks: [for (item, j) in dataDisksDefinition: {
        diskSizeGB: item.diskSizeGB
        lun: j
        caching: 'None'
        createOption: 'Attach'
        managedDisk: {
          id: resourceId('Microsoft.Compute/disks', '${virtualMachineNameSuffix}${format('{0:D2}', i)}_datadisk_${j}')
          storageAccountType: osDiskType
        }
      }]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri:storageId
      }
    }
    licenseType: (enableHybridBenefit ? 'Windows_Server' : json('null'))
  }
  dependsOn: [
    nic
   // dataDisk
  ]
}]

resource sql_vm 'Microsoft.SqlVirtualMachine/SqlVirtualMachines@2017-03-01-preview' = [for i in range(startIndex, vmCount): {
  name: '${virtualMachineNameSuffix}${format('{0:D2}', i)}'
  location: location
  properties: {
    virtualMachineResourceId: resourceId('Microsoft.Compute/virtualMachines', '${virtualMachineNameSuffix}${format('{0:D2}', i)}')
    sqlManagement: 'Full'
    sqlServerLicenseType: sqlServerLicenseType
    sqlVirtualMachineGroupResourceId: (!empty(sqlVmGroupName)) ? resourceId('Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups', sqlVmGroupName) : null
    autoPatchingSettings: {
      enable: false
    }
    /* autoBackupSettings: {
      enable: enableAutoBackup
      retentionPeriod: ((enableAutoBackup == true) ? autoBackupRetentionPeriod : null)
      storageAccountUrl: ((enableAutoBackup == true) ? reference(resourceId(autoBackupStorageAccountResourceGroup, 'Microsoft.Storage/storageAccounts', autoBackupStorageAccountName), '2018-07-01').primaryEndpoints.blob : null)
      storageAccessKey: ((enableAutoBackup == true) ? first(listKeys(resourceId(autoBackupStorageAccountResourceGroup, 'Microsoft.Storage/storageAccounts', autoBackupStorageAccountName), '2018-07-01').keys).value : null)
      enableEncryption: ((enableAutoBackup == true) ? enableAutoBackupEncryption : null)
      password: (((enableAutoBackup == true) && (enableAutoBackupEncryption == true)) ? autoBackupEncryptionPassword : null)
      backupSystemDbs: ((enableAutoBackup == true) ? autoBackupSystemDbs : null)
      backupScheduleType: ((enableAutoBackup == true) ? autoBackupScheduleType : null)
      fullBackupFrequency: (((enableAutoBackup == true) && (autoBackupScheduleType == 'Manual')) ? autoBackupFullBackupFrequency : null)
      fullBackupStartTime: (((enableAutoBackup == true) && (autoBackupScheduleType == 'Manual')) ? autoBackupFullBackupStartTime : null)
      fullBackupWindowHours: (((enableAutoBackup == true) && (autoBackupScheduleType == 'Manual')) ? autoBackupFullBackupWindowHours : null)
      logBackupFrequency: (((enableAutoBackup == true) && (autoBackupScheduleType == 'Manual')) ? int(autoBackupLogBackupFrequency) : null)
    }
    keyVaultCredentialSettings: {
      azureKeyVaultUrl: ((enableAkvEkm == true) ? sqlAkvUrl : null)
      credentialName: ((enableAkvEkm == true) ? sqlAkvCredentialName : null)
      enable: enableAkvEkm
      servicePrincipalName: ((enableAkvEkm == true) ? sqlAkvPrincipalName : null)
      servicePrincipalSecret: ((enableAkvEkm == true) ? sqlAkvPrincipalSecret : null)
    }*/
    storageConfigurationSettings: {
      diskConfigurationType: 'NEW'
      storageWorkloadType: sqlStorageWorkloadType
      sqlDataSettings: {
        luns: dataDisksLUNs
        defaultFilePath: dataPath
      }
      sqlLogSettings: {
        luns: logDisksLUNs
        defaultFilePath: logPath
      }
      sqlTempDbSettings: {
        luns: tempDBDisksLUNs
        defaultFilePath: tempDBPath
      }
    }
    serverConfigurationsManagementSettings: {
      sqlConnectivityUpdateSettings: {
        connectivityType: sqlConnectivityType
        port: sqlPortNumber
        sqlAuthUpdateUserName: sqlAuthUpdateUserName
        sqlAuthUpdatePassword: sqlAuthUpdatePassword
      }
      additionalFeaturesServerConfigurations: {
        isRServicesEnabled: rServicesEnabled
      }
    }
    wsfcDomainCredentials: {
      clusterBootstrapAccountPassword: (!empty(sqlVmGroupName)) ? sqlClusterBootstrapAccountPassword : null
      clusterOperatorAccountPassword: (!empty(sqlVmGroupName)) ? sqlClusterOperatorAccountPassword : null
      sqlServiceAccountPassword: (!empty(sqlVmGroupName)) ? sqlServiceAccountPassword : null
    }
  }
  dependsOn: [
    vm
    extension_domainJoin
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
      Options: 3 // Join Domain and Create Computer Account
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
resource deleteLock 'Microsoft.Authorization/locks@2016-09-01' = [for i in range(0, vmCount): if (enableResourceLock) {
  name: '${virtualMachineNameSuffix}${format('{0:D2}', i + startIndex)}-delete-lock'
  scope: vm[i]
  properties: {
    level: 'CanNotDelete'
    notes: 'Enabled as part of IaC Deployment'
  }
}]

output vmName string = vm[0].name
