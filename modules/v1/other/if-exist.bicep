targetScope = 'resourceGroup'

@description('Resource name to check in current scope (resource group)')
param resourceID string

@description('Resource name to check in current scope (resource group)')
param apiVersion string


// The script below performs an 'az resource list' command to determine whether a resource exists



output exists bool = length(reference(resourceID,apiVersion).resourceGuid) > 0
