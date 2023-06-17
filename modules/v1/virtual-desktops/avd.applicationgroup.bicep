@description('AVD Application group Name')
param appGroupName string

@description('Location for the Workspace')
param location string

@description('Application Group Type')
param appgroupType string 

@description('hostpool ID')
param hostpoolID string = ''

@description('Application Alias')
param applicationAlias string = ''

@description('Application Path')
param applicationPath string = ''

@description('Application Description')
param applicationDesc string = ''


resource appGroup 'Microsoft.DesktopVirtualization/applicationgroups@2019-12-10-preview' = {
  name: appGroupName
  location: location
  properties: {
      friendlyName: appGroupName
      applicationGroupType: appgroupType
      hostPoolArmPath: hostpoolID
    }
  }

  resource symbolicname 'Microsoft.DesktopVirtualization/applicationGroups/applications@2019-12-10-preview' = if (appgroupType == 'RemoteApp') {
    name: applicationAlias
    parent: appGroup
    properties: {
      commandLineSetting: 'Allow'
      description: applicationDesc
      filePath: applicationPath
      friendlyName: appGroupName
      iconIndex: 0
      iconPath: applicationPath
      showInPortal: true
    }
  }

  output appGroupId string = appGroup.id
