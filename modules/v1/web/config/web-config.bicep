@description('Web/Function App Name')
param appName string

@description('Web/Fucntion App Configurations')
param properties object


resource AppSettings 'Microsoft.Web/sites/config@2022-03-01' = {
  name: '${appName}/appsettings'
  properties:  properties
}
