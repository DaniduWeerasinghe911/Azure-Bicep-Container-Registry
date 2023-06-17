@description('Name of web application')
param appName string

@description('Location for resources to be created')
param location string = resourceGroup().location

@description('Application ')
param netFrameworkVersion string = ''

@description('Resource Id of the server farm to host the application')
param serverFarmId string

@description('The type of Web App to create (web, api, ...)')
param webAppKind string = 'web'

@description('Use ARR Affinity.  Keep enabled if app not truely stateless.')
param clientAffinityEnabled bool = true

@description('Keeps web app as always on (hot).')
param alwaysOn bool = false

@description('Sets 32-bit vs 64-bit worker architecture')
param use32BitWorkerProcess bool = true

@description('Comma delimited string of allowed origins hosts.  Use * for allow-all.')
param corsAllowedOrigins string = ''

@description('True/False on whether to enable Support Credentials for CORS.')
param corsSupportCredentials bool = false

@description('True/False on whether to enable Support Credentials for CORS.')
param vnetRouteAllEnabled bool = false

@description('Is Deployed from package')
param isPackageDeploy bool = false

@description('Is Deployed from package')
param packageUri string =''

@description('Object containing diagnostics settings. If not provided diagnostics will not be set.')
@metadata({
  name: 'Diagnostic settings name'
  workspaceId: 'Log analytics resource id'
  storageAccountId: 'Storage account resource id'
  eventHubAuthorizationRuleId: 'EventHub authorization rule id'
  eventHubName: 'EventHub name'
  enableLogs: 'Enable logs'
  enableMetrics: 'Enable metrics'
  retentionPolicy: {
    days: 'Number of days to keep data'
    enabled: 'Enable retention policy'
  }
})
param diagSettings object = {}

@description('Name of App Insights')
param appInsightsName string

@description('Enable a Can Not Delete Resource Lock. Useful for production workloads.')
param enableResourceLock bool = false

@description('Object containing resource tags.')
@metadata({
  Purpose: 'Sample Bicep Template'
  Environment: 'Development'
  Owner: 'sample.user@arinco.com.au'
})
param tags object = {}

var corsAllowedOrigins_var = split(corsAllowedOrigins, ',')

resource webApplication 'Microsoft.Web/sites@2021-01-15' = {
  name: appName
  location: location
  tags: !empty(tags) ? tags : null
  identity:{
    type: 'SystemAssigned'
  }
  kind: webAppKind
  properties: {
    httpsOnly: true
    serverFarmId: serverFarmId
    clientAffinityEnabled: clientAffinityEnabled
    siteConfig: {
      alwaysOn: alwaysOn
      use32BitWorkerProcess: use32BitWorkerProcess
      scmIpSecurityRestrictionsUseMain: true
      http20Enabled: true
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      vnetRouteAllEnabled: vnetRouteAllEnabled
      cors: {
        allowedOrigins: corsAllowedOrigins_var
        supportCredentials: corsSupportCredentials
      }
    netFrameworkVersion: empty(netFrameworkVersion) ? json('null') : netFrameworkVersion
    }
  }
  
  //  leaving this here if the stack needs to be changed, the default is dotnetcore
  //  resource webAppConfig 'config' = {
  //    name: 'metadata'
  //    properties: {
  //        CURRENT_STACK: 'dotnetcore'
  //      }
  //    }

}

resource webApp_diag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(diagSettings)) {
  name: empty(diagSettings) ? 'dummy-value' : diagSettings.name
  scope: webApplication
  properties: {
    workspaceId: empty(diagSettings.workspaceId) ? json('null') : diagSettings.workspaceId
    storageAccountId: empty(diagSettings.storageAccountId) ? json('null') : diagSettings.storageAccountId
    eventHubAuthorizationRuleId: empty(diagSettings.eventHubAuthorizationRuleId) ? json('null') : diagSettings.eventHubAuthorizationRuleId 
    eventHubName: empty(diagSettings.eventHubName) ? json('null') : diagSettings.eventHubName
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: diagSettings.enableLogs
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: diagSettings.enableLogs
      }
      {
        category: 'AppServiceAppLogs'
        enabled: diagSettings.enableLogs
      }
      {
        category: 'AppServiceAuditLogs'
        enabled: diagSettings.enableLogs
      }
      {
        category: 'AppServiceIPSecAuditLogs'
        enabled: diagSettings.enableLogs
      }
      {
        category: 'AppServicePlatformLogs'
        enabled: diagSettings.enableLogs
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
  dependsOn: [
    webApplication
  ]
}

//add app insights
resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' existing = {
  name: appInsightsName
}


resource appServiceSiteExtension 'Microsoft.Web/sites/siteextensions@2020-06-01' = {
  name: '${webApplication.name}/Microsoft.ApplicationInsights.AzureWebsites'
  dependsOn: [
    appInsights
  ]
}

resource appServiceAppSettings 'Microsoft.Web/sites/config@2020-06-01' = {
  name: '${webApplication.name}/appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsights.properties.InstrumentationKey
  }
  dependsOn: [
    appServiceSiteExtension
  ]
}

resource FunctionAppZipDeploy 'Microsoft.Web/sites/extensions@2022-03-01' = if(isPackageDeploy) {
  parent: webApplication
  name: 'MSDeploy'
  properties: {
      packageUri: packageUri
  }
}


// Resource Lock
resource deleteLock 'Microsoft.Authorization/locks@2016-09-01' = if (enableResourceLock) {
  name: '${appName}-delete-lock'
  scope: webApplication
  properties: {
    level: 'CanNotDelete'
    notes: 'Enabled as part of IaC Deployment'
  }
  dependsOn: [
    webApplication
  ]
}


output name string = webApplication.name
output id string = webApplication.id
output systemId string = webApplication.identity.principalId
output systemIdTenant string = webApplication.identity.tenantId
output siteConfig object = webApplication.properties.siteConfig
