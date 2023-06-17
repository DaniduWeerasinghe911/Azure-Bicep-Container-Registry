@description('URL of the Storage Account\'s table endpoint to retrieve certificate information from')
param StorageAccountTableUrl string

@description('The ID of an App Service Plan')
param appServicePlanID string

@description('Name of SCEPman\'s app service')
param appServiceName string

@description('Base URL of SCEPman')
param scepManBaseURL string

@description('URL of the key vault')
param keyVaultURL string

@description('Name of company or organization for certificate subject')
param OrgName string

@description('License Key for SCEPman')
param license string = ''

@description('The full URI where SCEPman artifact binaries are stored')
param WebsiteArtifactsUri string

@description('Shared Services Resource Group Name')
param shdSvcsRgName string = 'Shared-RG'

@description('Resource Group')
param location string

param subnetID string

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

resource appServiceName_resource 'Microsoft.Web/sites@2021-02-01' = {
  name: appServiceName
  location: location
  properties: {
    serverFarmId: appServicePlanID
    httpsOnly: false
    clientAffinityEnabled: false
    siteConfig: {
      vnetRouteAllEnabled: true
      alwaysOn: true
      use32BitWorkerProcess: false
      ftpsState: 'Disabled'
      appSettings: [
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: WebsiteArtifactsUri
        }
        {
          name: 'AppConfig:BaseUrl'
          value: scepManBaseURL
        }
        {
          name: 'AppConfig:LicenseKey'
          value: license
        }
        {
          name: 'AppConfig:AuthConfig:TenantId'
          value: subscription().tenantId
        }
        {
          name: 'AppConfig:UseRequestedKeyUsages'
          value: 'true'
        }
        {
          name: 'AppConfig:ValidityPeriodDays'
          value: '730'
        }
        {
          name: 'AppConfig:IntuneValidation:ValidityPeriodDays'
          value: '365'
        }
        {
          name: 'AppConfig:DirectCSRValidation:Enabled'
          value: 'true'
        }
        {
          name: 'AppConfig:IntuneValidation:DeviceDirectory'
          value: 'AADAndIntune'
        }
        {
          name: 'AppConfig:KeyVaultConfig:KeyVaultURL'
          value: keyVaultURL
        }
        {
          name: 'AppConfig:AzureStorage:TableStorageEndpoint'
          value: StorageAccountTableUrl
        }
        {
          name: 'AppConfig:KeyVaultConfig:RootCertificateConfig:CertificateName'
          value: 'SCEPman-Root-CA-V1'
        }
        {
          name: 'AppConfig:ValidityClockSkewMinutes'
          value: '1440'
        }
        {
          name: 'AppConfig:KeyVaultConfig:RootCertificateConfig:Subject'
          value: 'CN=SCEPman-Root-CA-V1, OU=${subscription().tenantId}, O="${OrgName}"'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
      ]
    }
  }
}

resource webAppNetworkConfig 'Microsoft.Web/sites/networkConfig@2020-06-01' = {
  name: '${appServiceName}/VirtualNetwork'
  properties: {
    subnetResourceId: subnetID
  }
  dependsOn: [
    appServiceName_resource 

  ]
}

resource webApp_diag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(diagSettings)) {
  name: empty(diagSettings) ? 'dummy-value' : diagSettings.name
  scope: appServiceName_resource
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

  ]
}

//add app insights
resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' existing = {
  name: appInsightsName
  scope:resourceGroup(shdSvcsRgName)

}

resource appServiceSiteExtension 'Microsoft.Web/sites/siteextensions@2020-06-01' = {
  name: '${appServiceName_resource.name}/Microsoft.ApplicationInsights.AzureWebsites'
  dependsOn: [
    appInsights
  ]
}
