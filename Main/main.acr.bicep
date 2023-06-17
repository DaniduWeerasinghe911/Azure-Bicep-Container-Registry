targetScope = 'subscription'

@description('Resource Group Name')
param rgName string

@description('Location Name')
param location string

@description('ACR Name')
param acrName string


resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: rgName
  location: location
}

module acr '../modules/v1/acr/acr.bicep' = {
  scope: rg
  name: 'deploy_acr'
  params: {
    acrName: acrName
    location: location
  }
}
