// Function App that is used for code deployments (not docker) and VNET Integrated
// Requries an App Service Plan or Premium Function App Plan
// Function Runtime v3
// Assumes existing App Insights for monitoring
// Assumes existing storage account
// Must provide Subnet Resource ID to integrate with and assumes subnet delegation already done

@description('Name of Function App')
param fncAppName string

@description('Location for resources to be created')
param location string = resourceGroup().location

@description('The language worker runtime to load in the function app.')
@allowed([
  'node'
  'dotnet'
  'java'
  'python'
  'powershell'
])
param functionRuntime string

@description('ResourceId of Storage Account to host Function App.')
param storageAccountId string

@description('ResourceId of Application Insights instance for Function App monitoring.')
param appInsightsId string

@description('Subnet Id of VNET to integrate with. Assumes delegation already done.')
param subnetId string = ''

@description('Node.JS version. Only needed if runtime is node')
param nodeVersion string = '~12'

@description('Only applies if you using Consumption or Premium service plans.')
param preWarmedInstanceCount int = 1

@description('Resource Id of the server farm to host the function app. Needs to be an App Service Plan or Premium Plan')
param serverFarmId string

@description('Sets 32-bit vs 64-bit worker architecture')
param use32BitWorkerProcess bool = true

@description('Array of allowed origins hosts.  Use [*] for allow-all.')
param corsAllowedOrigins array = []

@description('True/False on whether to enable Support Credentials for CORS.')
param corsSupportCredentials bool = false

@description('Enable when you are VNET integrated and need non-HTTP triggers for services inside a VNET.')
param functionsRuntimeScaleMonitoringEnabled bool = false

@description('Additional App Settings to include on top of that required for this function app')
@metadata({
  note: 'Sample input'
  addAppSettings: [
    {
      name: 'key-name'
      value: 'key-value'
    }
  ]
})
param addAppSettings array = []

@description('Object containing diagnostics settings. If not provided diagnostics will not be set.')
param diagSettings object = {}

@description('Enable a Can Not Delete Resource Lock. Useful for production workloads.')
param enableResourceLock bool = false

@description('Object containing resource tags.')
param tags object = {}

@description('Is Vnet Integration Enabled')
param isVnetIntegrated bool

@description('Force all traffic to go via VNET')
param vnetRouteAllEnabled bool = false

@description('Is Deployed from package')
param isPackageDeploy bool = false

@description('Is Deployed from package')
param packageUri string =''

// Extract out names
var storageAccountName = split(storageAccountId,'/')[8]

// Build base level App Settings needed for Function App
var baseAppSettings = [
  {
    name: 'AzureWebJobsStorage'
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountId, '2019-06-01').keys[0].value}'
  }
  {
    name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountId, '2019-06-01').keys[0].value}'
  }
  {
    name: 'AzureWebJobsStorage'
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountId, '2019-06-01').keys[0].value}'
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: functionRuntime
  }
  {
    name: 'WEBSITE_NODE_DEFAULT_VERSION'
    value: nodeVersion
  }
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: '~3'
  }
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: reference(appInsightsId, '2020-02-02-preview').InstrumentationKey
  }
]

var appSettings = union(baseAppSettings,addAppSettings)

// Resource Definition
resource fncApp 'Microsoft.Web/sites@2021-01-15' = {
  name: fncAppName
  location: location
  tags: !empty(tags) ? tags : null
  identity:{
    type: 'SystemAssigned'
  }
  kind: 'functionapp'
  properties: {
    httpsOnly: true           // Security Setting
    serverFarmId: serverFarmId
    siteConfig: {
      use32BitWorkerProcess: use32BitWorkerProcess
      http20Enabled: true     // Security Setting
      minTlsVersion: '1.2'    // Security Setting
      scmMinTlsVersion: '1.2' // Security Setting
      ftpsState: 'Disabled'   // Security Setting
      preWarmedInstanceCount: preWarmedInstanceCount
      vnetRouteAllEnabled: vnetRouteAllEnabled
      functionsRuntimeScaleMonitoringEnabled: functionsRuntimeScaleMonitoringEnabled
      cors: {
        allowedOrigins: corsAllowedOrigins
        supportCredentials: corsSupportCredentials
      }
      appSettings: appSettings
    }
  }  
}

// VNET Integration
resource networkConfig 'Microsoft.Web/sites/networkConfig@2020-06-01' = if(isVnetIntegrated){
  parent: fncApp
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: subnetId
    swiftSupported: true
  }
}

// Add ZipDeploy for Function App
resource FunctionAppZipDeploy 'Microsoft.Web/sites/extensions@2022-03-01' = if(isPackageDeploy) {
  parent: fncApp
  name: 'MSDeploy'
  properties: {
      packageUri: packageUri
  }
}

// resource siteConfig 'Microsoft.Web/sites/config@2022-03-01' = {
// name :'${fncApp.name}/appsettings'
// properties:fncApp.properties.siteConfig
// dependsOn:FunctionAppZipDeploy
// }

// Diagnostics
resource diagnostics 'Microsoft.insights/diagnosticsettings@2017-05-01-preview' = if (!empty(diagSettings)) {
  name: empty(diagSettings) ? 'dummy-value' : diagSettings.name
  scope: fncApp
  properties: {
    workspaceId: empty(diagSettings.workspaceId) ? json('null') : diagSettings.workspaceId
    storageAccountId: empty(diagSettings.storageAccountId) ? json('null') : diagSettings.storageAccountId
    eventHubAuthorizationRuleId: empty(diagSettings.eventHubAuthorizationRuleId) ? json('null') : diagSettings.eventHubAuthorizationRuleId
    eventHubName: empty(diagSettings.eventHubName) ? json('null') : diagSettings.eventHubName
    
    logs: [
      {
        category: 'FunctionAppLogs'
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
  name: '${fncAppName}-delete-lock'
  scope: fncApp
  properties: {
    level: 'CanNotDelete'
    notes: 'Enabled as part of IaC Deployment'
  }
}

// Output Resource Name and Resource Id as a standard to allow module referencing.
output name string = fncApp.name
output id string = fncApp.id
output systemId string = fncApp.identity.principalId
output systemIdTenant string = fncApp.identity.tenantId
output siteConfig object = fncApp.properties.siteConfig
