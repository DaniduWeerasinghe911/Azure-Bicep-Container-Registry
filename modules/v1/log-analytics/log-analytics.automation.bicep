// Log Analytics Workspace Automation Link

@description('The name of the resource.')
param workspaceName string

@description('Location of the resource.')
param automationAccountName string




resource logAnalyticsAutomation 'Microsoft.OperationalInsights/workspaces/linkedServices@2020-08-01' = if (!empty(automationAccountName)) {
  name: '${workspaceName}/Automation'
  properties: {
    resourceId: resourceId('Microsoft.Automation/automationAccounts', automationAccountName)
  }
}
