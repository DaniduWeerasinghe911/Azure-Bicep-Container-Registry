// Helper Bicep Module to return the Private IP address of an Azure Firewall
// Assumes this module is scoped to the resource group hosting the firewall

@description('Resource Id of Azure Firewall')
param firewallId string

output ipAddress string = reference(firewallId).ipConfigurations[0].properties.privateIPAddress
