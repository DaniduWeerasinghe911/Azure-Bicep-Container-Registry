// GET Web Availability Test with associated alert
@description('Name of the Web Service you wish to monitor')
param serviceName string

@description('URL of the test to perform the Ping Test')
param pingTestURL string

@description('Array of ResourceIds of Actions Groups')
param actionGroups array

@description('ResourceId of App Insights')
param appInsightsId string

@description('Location of resource')
param location string = resourceGroup().location

@description('Response code for the GET Ping Web Test.  Normally 200.')
param expectedResponseCode string = '200'

@description('Array of Web Test Locations')
param webTestLocations array = [
  'us-il-ch1-azr'
  'us-ca-sjc-azr'
  'apac-sg-sin-azr'
  'emea-gb-db3-azr'
  'emea-au-syd-edge'
]

@description('Frequency of Web Test')
param webTestFrequency int = 300

@description('Timeout period for Web Test')
param webTestTimeout int = 120

@description('Alert Severity')
param alertSeverity int = 0

@description('Number of Failed Locations until Alert')
param failedLocationCount int = length(webTestLocations) / 2   // Default to ~50%

resource pingWebTest 'Microsoft.Insights/webtests@2020-10-05-preview' = {
  location: location
  tags: {
    'hidden-link:${appInsightsId}': 'Resource'
  }
  name: '${serviceName}-pingWebTest'
  kind: 'ping'
  properties: {
    SyntheticMonitorId: '${serviceName}-pingWebTest'
    Name: '${serviceName} - Availability Test'
    Description: 'A web test for performing a ping (HTTP GET) to test availability of the targeted web app'
    Enabled: true
    Frequency: webTestFrequency
    Timeout: webTestTimeout
    Kind: 'ping'
    RetryEnabled: true
    Locations: [for item in webTestLocations: {
      Id: item
    }]
    Configuration: {
      WebTest: '<WebTest Name="${serviceName}-pingWebTest" Enabled="True" Timeout="${webTestTimeout}" xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2010" PreAuthenticate="True" Proxy="default" StopOnError="False"><Items><Request Method="GET" Version="1.1" Url="${pingTestURL}" ThinkTime="0" Timeout="${webTestTimeout}" ParseDependentRequests="False" FollowRedirects="True" RecordResult="True" Cache="False" ResponseTimeGoal="0" Encoding="utf-8" ExpectedHttpStatusCode="${expectedResponseCode}" IgnoreHttpStatusCode="False" /></Items></WebTest>'
    }
  }
}

resource alert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${serviceName} - Failed Ping Web Test'
  location: 'global'
  tags: {
    'hidden-link:${appInsightsId}': 'Resource'
    'hidden-link:${pingWebTest.id}': 'Resource'
  }
  properties: {
    description: 'Availability Ping Test for ${serviceName} has failed from at least ${failedLocationCount} test locations.'
    severity: alertSeverity
    enabled: true
    scopes: [
      appInsightsId
      pingWebTest.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.WebtestLocationAvailabilityCriteria'
      webTestId: pingWebTest.id
      componentId: appInsightsId
      failedLocationCount: failedLocationCount
    }
    actions: [for item in actionGroups: {
      actionGroupId: item
    }]
  }
}
