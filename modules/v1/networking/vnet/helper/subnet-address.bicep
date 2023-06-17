
param subid string = '6da6ad04-e536-4124-a437-c62b91ca3cff'

param rgName string = 'rg-hub-dckloud'

param vnetName string = 'vnet-hub-dckloud'

param subnetName string = 'snet-public'



resource vnet 'Microsoft.Network/virtualNetworks@2020-07-01' existing = {
  scope:resourceGroup(subid,rgName)
  name: vnetName
}

resource modify_subnet 'Microsoft.Network/virtualNetworks/subnets@2020-07-01' existing = {
  parent: vnet
  name: subnetName
}

// resource ipallocation 'Microsoft.Network/networkProfiles@2022-05-01' existing = [for i in range(0,length(modify_subnet.properties.ipConfigurationProfiles) ) :{
//   name: 'temp${i}'
// }]

resource ipallocation 'Microsoft.Network/networkProfiles@2022-05-01' existing = {
  name: 'temp'
}


output subnetAddress  array = modify_subnet.properties.ipConfigurationProfiles
output address string = modify_subnet.properties.addressPrefix
output ipallocation array = ipallocation.
//output address2 string = modify_subnet.properties.
