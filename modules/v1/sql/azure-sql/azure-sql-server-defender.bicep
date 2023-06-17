// Enables Defender on Azure SQL Server.  Uses SQL Server Managed Identities to grant access to Storage Account to allow it to access those behind storage firewalls

@description('Name of existing Azure SQL Server')
param sqlServerName string

@description('Name of Storage Account to store Vulnerability Assessments.')
param storageName string

@description('Resource Group of Storage Account to store Vulnerability Assessments.')
param storageResourceGroup string

@description('Subscription Id of Storage Account to store Vulnerability Assessments.')
param storageSubscriptionId string

@description('Specifies an array of alerts that are disabled.')
param disabledAlerts array = []

@description('Specifies that the alert is sent to the account administrators.')
param emailAccountAdmins bool = false

@description('Array of e-mail addresses to which the alert and vulnerability scans are sent')
param emailAddresses array

@description('Enable Recurring Scans')
param recurringScans bool = true

@description('Specifies the number of days to keep in the audit logs')
param retentionDays int = 0

// Get existing Azure SQL Resource Object
resource sqlServer 'Microsoft.Sql/servers@2019-06-01-preview' existing = {
  name: sqlServerName
}

// Get existing Storage account Object
resource storage 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storageName
}

module role_def './helper/storage-role-definition.bicep' = {
  scope: resourceGroup(storageSubscriptionId, storageResourceGroup)
  name: 'assign_${sqlServerName}_role'
  params: {
    sqlServerId: sqlServer.id
    storageName: storageName
  } 
}

resource alertPolicies 'Microsoft.Sql/servers/securityAlertPolicies@2017-03-01-preview' = {
  parent: sqlServer
  name: 'Default'
  properties: {
    state: 'Enabled'
    disabledAlerts: disabledAlerts
    emailAccountAdmins: emailAccountAdmins
    emailAddresses: emailAddresses
    retentionDays: retentionDays
  }
}

resource vuln_assess 'Microsoft.Sql/servers/vulnerabilityAssessments@2018-06-01-preview' = {
  parent: sqlServer
  name: 'default'
  properties: {
    storageContainerPath: '${storage.properties.primaryEndpoints.blob}vulnerability-assessment'
    recurringScans: {
      isEnabled: recurringScans
      emailSubscriptionAdmins: false
      emails: emailAddresses
    }
  }
  dependsOn: [
    alertPolicies
  ]
}
