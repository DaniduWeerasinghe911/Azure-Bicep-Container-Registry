@description('')
param location string

@description('Name of the container group')
param name string

@description('IP Address Type')
param ipAddressType string

@description('IP Address Type')
/*[
  {
      "port": "80",
      "protocol": "TCP"
  },
  {
      "port": "22",
      "protocol": "TCP"
  }
]*/
param ipAddressPorts array

@description('DNS Lable name for the container Group')
param dnsLableName string

@description('DNS Lable name for the container Group')
param subnetIds string

@description('File Share Name')
param fileShareName string

@description('Storage Account Name')
param storageAccountName string

var storageAccountId = resourceId(subscription().subscriptionId, resourceGroup().name, 'Microsoft.Storage/storageAccounts', storageAccountName)

@description('Name of the container group details')
@metadata(
    {
        name: 'sftp'
        properties: {
            image: 'atmoz/sftp:debian'
            ports: [
                {
                    protocol: 'TCP'
                    port: 22
                }
            ]
            environmentVariables: [
                {
                    name: 'SFTP_USERS'
                }
            ]
            resources: {
                requests: {
                    memoryInGB: 1
                    cpu: 1
                }
            }
            volumeMounts: [
                {
                    name: 'sftpvolume'
                    mountPath: ' /home/flexiPurchase/upload'
                    readOnly: false
                }
            ]
        }
    }
)
param containers array

@description('Container group SKU')
param sku string

@description('Container group SKU')
param ostype string

resource containerGroups 'Microsoft.ContainerInstance/containerGroups@2021-10-01' = {
    name: name
    location: location
    properties: {
        containers: containers
        osType: ostype
        sku: sku
        initContainers: [

        ]
        restartPolicy: 'OnFailure'
        volumes: [
            {
                name: 'sftpvolume'
                azureFile: {
                    shareName: fileShareName
                    readOnly: false
                    storageAccountName: storageAccountName
                    storageAccountKey:listKeys(storageAccountId, '2019-06-01').keys[0].value}
            }
        ]
        ipAddress: {
            type: ipAddressType
            ports: ipAddressPorts
            dnsNameLabel:dnsLableName
        }
    /*    subnetIds: [
            {
                id: subnetIds
            }
        ]*/
    }
}
