// Log Analytics Workspace

@description('The name of the resource.')
param workspaceName string

@description('Location of the resource.')
param location string = resourceGroup().location

@description('Data retention period.')
@minValue(7)
@maxValue(730)
param retentionInDays int = 90

@description('Capacity based reservation for data ingestion in GB. Must be in multiples of 100. Leave as 0 if no reservation.')
param capacityReservation int = 0

@metadata({
  name: 'Solution name'
  product: 'Product name'
  publisher: 'Publisher name'
  promotionCode: 'Promotion code (if applicable)'
})
@description('Solutions to add to workspace')
param solutions array = []

@description('Name of automation account to link to workspace')
param automationAccountName string = ''

@metadata({
  name: 'Data source name'
  kind: 'Data source kind'
  properties: 'Object containing data source properties'
})
@description('Datasources to add to workspace')
param dataSources array = []

@metadata({
  tagKey: 'tag value'
})
@description('Object containing resource tags.')
param tags object = {}

@description('Enable a Can Not Delete Resource Lock.  Useful for production workloads.')
param enableResourceLock bool = false

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
@description('Object containing diagnostics settings. If not provided diagnostics will not be set.')
param diagSettings object = {}

var vmInsightsName = 'vmInsights(${workspaceName})'
var ServiceMap = 'ServiceMap(${workspaceName})'

// Resource Definition
resource loganalytics 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: workspaceName
  location: location
  tags: !empty(tags) ? tags : json('null')
  properties: {
    sku: {
      name: 'PerGB2018'
      capacityReservationLevel: (capacityReservation == 0) ? json('null') : capacityReservation
    }
    retentionInDays: retentionInDays
    features: {
      searchVersion: 1
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

resource solutionsVMInsights 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: vmInsightsName
  location: location
  properties: {
    workspaceResourceId: loganalytics.id
  }
  plan: {
    name: vmInsightsName
    publisher: 'Microsoft'
    product: 'OMSGallery/VMInsights'
    promotionCode: ''
  }
}
// Additional Solution
resource solutionsVMServices 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: ServiceMap
  location: location
  properties: {
    workspaceResourceId: loganalytics.id
  }
  plan: {
    name: ServiceMap
    publisher: 'Microsoft'
    product: 'OMSGallery/ServiceMap'
    promotionCode: ''
  }
}


resource logAnalyticsAutomation 'Microsoft.OperationalInsights/workspaces/linkedServices@2020-08-01' = if (!empty(automationAccountName)) {
  name: '${loganalytics.name}/Automation'
  properties: {
    resourceId: resourceId('Microsoft.Automation/automationAccounts', automationAccountName)
  }
}

resource logAnalyticsSolutions 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = [for solution in solutions: {
  name: '${solution.name}(${loganalytics.name})'
  location: location
  properties: {
    workspaceResourceId: loganalytics.id
  }
  plan: {
    name: '${solution.name}(${loganalytics.name})'
    product: solution.product
    publisher: solution.publisher
    promotionCode: solution.promotionCode
  }
}]

resource logAnalyticsDataSource 'Microsoft.OperationalInsights/workspaces/dataSources@2020-08-01' = [for dataSource in dataSources: {
  name: '${loganalytics.name}/${dataSource.name}'
  kind: dataSource.kind
  properties: dataSource.properties
}]

// Diagnostics
resource diagnostics 'Microsoft.insights/diagnosticsettings@2017-05-01-preview' = if (!empty(diagSettings)) {
  name: empty(diagSettings) ? 'dummy-value' : diagSettings.name
  scope: loganalytics
  properties: {
    workspaceId: empty(diagSettings.workspaceId) ? json('null') : diagSettings.workspaceId
    storageAccountId: empty(diagSettings.storageAccountId) ? json('null') : diagSettings.storageAccountId
    eventHubAuthorizationRuleId: empty(diagSettings.eventHubAuthorizationRuleId) ? json('null') : diagSettings.eventHubAuthorizationRuleId
    eventHubName: empty(diagSettings.eventHubName) ? json('null') : diagSettings.eventHubName

    logs: [
      {
        category: 'Audit'
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
  name: '${workspaceName}-delete-lock'
  scope: loganalytics
  properties: {
    level: 'CanNotDelete'
    notes: 'Enabled as part of IaC Deployment'
  }
}

// Output Resource Name and Resource Id as a standard to allow module referencing.
output name string = loganalytics.name
output id string = loganalytics.id
