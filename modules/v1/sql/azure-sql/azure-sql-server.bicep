// Azure SQL Server only.  Create Databases, Threat Protection and Audit settings seperately

@description('Name of the Azure SQL resource')
param sqlServerName string

@description('Location of the resource.')
param location string = resourceGroup().location

@description('SQL Administrator credentials - Username')
@secure()
param sqlAdminLogin string
@description('SQL Administrator credentials - Password')
@secure()
param sqlAdminPassword string

@description('Name of the AAD User or Group to grant as SQL Admin via AAD.')
param aadAdminLogin string
@description('Object ID of the AAD User or Group to grant as SQL Admin via AAD.  Must be defined if aadAdminLogin defined.')
param aadAdminObjectId string

@description('Enable/Disable Public Network Access. Only Disable if you wish to restrict to just private endpoints and VNET.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

@description('The server connection type. - Default, Proxy, Redirect.  Note private link requires Proxy.')
@allowed([
  'Default'
  'Proxy'
  'Redirect'
])
param connectionType string = 'Default'

@description('Object containing resource tags.')
param tags object = {}

@description('Enable a Can Not Delete Resource Lock.  Useful for production workloads.')
param enableResourceLock bool = false


resource sqlServer 'Microsoft.Sql/servers@2019-06-01-preview' = {
  name: sqlServerName
  location: location
  tags: !empty(tags) ? tags : json('null')
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    publicNetworkAccess: publicNetworkAccess
    minimalTlsVersion: '1.2'
  }
}

// SQL Server Connection Policy
resource connectionPolicy 'Microsoft.Sql/servers/connectionPolicies@2014-04-01' = {
  parent: sqlServer
  name: 'default'
  properties: {
    connectionType: connectionType
  }
}

// SQL Server AAD Admins
resource aad_admin 'Microsoft.Sql/servers/administrators@2021-02-01-preview' = {
  parent: sqlServer
  name: 'ActiveDirectory'
  properties: {
    administratorType: 'ActiveDirectory'
    login: aadAdminLogin
    sid: aadAdminObjectId
    tenantId: subscription().tenantId
  }
}

// Resource Lock
resource deleteLock 'Microsoft.Authorization/locks@2016-09-01' = if (enableResourceLock) {
  name: '${sqlServerName}-delete-lock'
  scope: sqlServer
  properties: {
    level: 'CanNotDelete'
    notes: 'Enabled as part of IaC Deployment'
  }
}

// Output Resource Name and Resource Id as a standard to allow module referencing.
output name string = sqlServer.name
output id string = sqlServer.id
