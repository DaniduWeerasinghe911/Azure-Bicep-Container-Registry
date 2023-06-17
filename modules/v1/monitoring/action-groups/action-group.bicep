@description('Name of the Action Group')
param actionGroupName string

@description('Short Name of the Action Group')
@maxLength(12)
param actionGroupShortName string

@description('Array of Email Receiver Objects, containing Name and EmailAddress')
param emailReceivers array = []

@description('Array of SMS Receiver Objects, containing Name, CountryCode, PhoneNumver.')
param smsReceivers array = []

@description('Array of Webhook Receiver Objects, containing Name, serviceUri.')
param webhookReceivers array = []

// TO DO - add params and sample objects for the other types of action groups

resource actionGroupName_resource 'microsoft.insights/actionGroups@2019-06-01' = {
  name: actionGroupName
  location: 'Global'
  properties: {
    groupShortName: actionGroupShortName
    enabled: true
    emailReceivers: emailReceivers
    smsReceivers: smsReceivers
    webhookReceivers: webhookReceivers
    itsmReceivers: []
    azureAppPushReceivers: []
    automationRunbookReceivers: []
    voiceReceivers: []
    logicAppReceivers: []
    azureFunctionReceivers: []
  }
}
