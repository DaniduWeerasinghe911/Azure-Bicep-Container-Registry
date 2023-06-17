// Key Vault that forces use of Azure RBAC

@description('The name of the resource.')
param keyVaultName string

@description('Location of the resource.')
param location string = resourceGroup().location

@description('Key Vault SKU. Standard or Premium')
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

@description('Allows Azure VMs to access KeyVault.')
param enabledForDeployment bool = true

@description('Allows Azure Disk Encryption service to access KeyVault.')
param enabledForDiskEncryption bool = true

@description('Allows Azure Resource Manager to access KeyVault during deployments.')
param enabledForTemplateDeployment bool = true

@description('Set to Deny if you want to enable the KeyVault Firewall.')
@allowed([
  'Allow'
  'Deny'
])
param defaultNetworkAclAction string = 'Allow'

@description('Whether to allow Azure Services to bypass Network Acls.')
@allowed([
  'AzureServices'
  'None'
])
param networkAclBypass string = 'AzureServices'

@description('An array of CIDR ranges for KeyVault Network ACLs.')
param ipRules array = []

@description('An array of vnet ids for KeyVault Network ACLs.')
param virtualNetworkRules array = []

@description('Soft delete retention period')
param softDeleteRetentionInDays int = 90

@description('Enable purge protection. Irreversible.')
param enablePurgeProtection bool = true

@description('Object containing resource tags.')
param tags object = {}

@description('Enable a Can Not Delete Resource Lock.  Useful for production workloads.')
param enableResourceLock bool = false

@description('Object containing diagnostics settings. If not provided diagnostics will not be set.')
param diagSettings object = {}

// Resource Definition
resource keyvault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyVaultName
  location: location
  tags: !empty(tags) ? tags : json('null')
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: skuName
    }
    enabledForDeployment: bool(enabledForDeployment)
    enabledForDiskEncryption: bool(enabledForDiskEncryption)
    enabledForTemplateDeployment: bool(enabledForTemplateDeployment)
    enableSoftDelete: true  // This is enabled by default now by Microsoft
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enablePurgeProtection: enablePurgeProtection ? enablePurgeProtection : json('null')
    enableRbacAuthorization: true   // Force the use of Azure RBAC instead of Access Policy
    networkAcls: {
      bypass: networkAclBypass
      defaultAction: defaultNetworkAclAction
      ipRules: ipRules
      virtualNetworkRules: virtualNetworkRules
    }
  }
}

// Diagnostics
resource diagnostics 'Microsoft.insights/diagnosticsettings@2017-05-01-preview' = if (!empty(diagSettings)) {
  name: empty(diagSettings) ? 'dummy-value' : diagSettings.name
  scope: keyvault
  properties: {
    workspaceId: empty(diagSettings.workspaceId) ? json('null') : diagSettings.workspaceId
    storageAccountId: empty(diagSettings.storageAccountId) ? json('null') : diagSettings.storageAccountId
    eventHubAuthorizationRuleId: empty(diagSettings.eventHubAuthorizationRuleId) ? json('null') : diagSettings.eventHubAuthorizationRuleId
    eventHubName: empty(diagSettings.eventHubName) ? json('null') : diagSettings.eventHubName
    
    logs: [
      {
        category: 'AuditEvent'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }    
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: diagSettings.enableMetrics
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
    ]
  }
}

// Resource Lock
resource deleteLock 'Microsoft.Authorization/locks@2016-09-01' = if (enableResourceLock) {
  name: '${keyVaultName}-delete-lock'
  scope: keyvault
  properties: {
    level: 'CanNotDelete'
    notes: 'Enabled as part of IaC Deployment'
  }
}

// Output Resource Name and Resource Id as a standard to allow module referencing.
output name string = keyvault.name
output id string = keyvault.id

