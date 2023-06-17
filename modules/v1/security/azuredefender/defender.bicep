// Main template to deploy a set of landing zone components at a subscription level
targetScope = 'subscription'

@description('Specify the contact email for use within Azure Defender')
param alertsSecurityEmail string
@description('Specify the contact phone for use within Azure Defender')
param alertsSecurityPhone string

@description('Specify the resource ID of your Log Analytics workspace to collect ASC data.')
param workspaceId string

@allowed([
  'On'
  'Off'
])
param alertsToSecurity string = 'On'

@allowed([
  'On'
  'Off'
])
param alertsToAdmins string = 'On'

@description('Configuration for each Defender Setting')
param pricingSettings array = [
  {
    name: 'OpenSourceRelationalDatabases'
    state: 'Standard'
  }
  {
    name: 'VirtualMachines'
    state: 'Standard'
  }
  {
    name: 'SqlServers'
    state: 'Standard'
  }
  {
    name: 'SqlServerVirtualMachines'
    state: 'Standard'
  }
  {
    name: 'AppServices'
    state: 'Standard'
  }
  {
    name: 'StorageAccounts'
    state: 'Standard'
  }
  {
    name: 'KubernetesService'
    state: 'Standard'
  }
  {
    name: 'ContainerRegistry'
    state: 'Standard'
  }
  {
    name: 'KeyVaults'
    state: 'Standard'
  }
  {
    name: 'Dns'
    state: 'Standard'
  }
  {
    name: 'Arm'
    state: 'Standard'
  }
]

@description('Automatically enable new resources into the log analytics workspace')
@allowed([
  'On'
  'Off'
])
param autoProvision string = 'Off'

resource string 'Microsoft.Security/securityContacts@2017-08-01-preview' = {
  name: 'string'
  properties: {
    email: alertsSecurityEmail
    phone: alertsSecurityPhone
    alertNotifications: alertsToSecurity
    alertsToAdmins: alertsToAdmins
  }
}

resource defenderPricings 'Microsoft.Security/pricings@2018-06-01' = [for pricing in pricingSettings: {
  name: pricing.name
  properties: {
    pricingTier: pricing.state
  }
}]

resource workspacedefault 'Microsoft.Security/workspaceSettings@2017-08-01-preview' = {
  name: 'default'
  properties: {
    workspaceId: workspaceId
    scope: subscription().id
  }
}

resource Microsoft_Security_autoProvisioningSettings_default 'Microsoft.Security/autoProvisioningSettings@2017-08-01-preview' = {
  name: 'default'
  properties: {
    autoProvision: autoProvision
  }
}

