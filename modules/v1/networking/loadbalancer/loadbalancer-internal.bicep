// Bicep module to deploy a standard internal load balancer
@description('Name of Load Balancer')
param lbName string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('SKU of Load Balancer')
@allowed([
  'Basic'
  'Gateway'
  'Standard'
])
param lbSku string = 'Standard'

@description('Name of the VNet the internal load balancer will use')
param lbVnetName string

@description('Name of the subnet the internal load balancer will use')
param lbSubnetName string

@description('Name of the load balancing rule set')
param lbRuleName string = 'lbRules'

@description('Name of the load balancer health probe')
param lbProbeName string = 'lbHealthProbe'

@description('Port for load balancer to listen on')
param lbFrontEndPort int

@description('Port for load balancer to send traffic to')
param lbBackEndPort int

@description('Receive bidirectional TCP Reset on TCP flow idle timeout or unexpected connection termination. This element is only used when the protocol is set to TCP')
param lbEnableTcpReset bool = true

@description('Configures SNAT for the VMs in the backend pool to use the publicIP address specified in the frontend of the load balancing rule')
param lbDisableOutboundSnat bool = true

@description('Protocol for the Load Balancer to use')
@allowed([
  'All'
  'Tcp'
  'Udp'
])
param lbProtocol string = 'Tcp'

@description('Protocol for the health probe to use')
@allowed([
  'Http'
  'Https'
  'Tcp'
])
param lbProbeProtocol string = 'Tcp'

@description('Object containing resource tags.')
param tags object = {}

@description('Enable a Can Not Delete Resource Lock.  Useful for production workloads.')
param enableResourceLock bool = false

@description('Object containing diagnostics settings. If not provided diagnostics will not be set.')
param diagSettings object = {}

resource publicLoadBalancer 'Microsoft.Network/loadBalancers@2021-02-01' = {
  name: lbName
  location: location
  tags: tags
  sku: {
    name: lbSku
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'lbFrontEnd'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', lbVnetName, lbSubnetName)
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'lbBackEnd'
      }
    ]
    loadBalancingRules: [
      {
        name: lbRuleName
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', lbName, 'lbFrontEnd')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, 'lbBackEnd')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', lbName, lbProbeName)
          }
          protocol: lbProtocol
          frontendPort: lbFrontEndPort
          backendPort: lbBackEndPort
          enableTcpReset: lbEnableTcpReset
          disableOutboundSnat: lbDisableOutboundSnat
          idleTimeoutInMinutes: 15
        }
      }
    ]
    probes: [
      {
        name: lbProbeName
        properties: {
          protocol: lbProbeProtocol
          port: lbBackEndPort
          intervalInSeconds: 15
          numberOfProbes: 2
        }
      }
    ]
  }
}

// App Gateway Resource Diagnostics
resource diagnostics 'Microsoft.insights/diagnosticsettings@2021-05-01-preview' = if (!empty(diagSettings)) {
  name: empty(diagSettings) ? 'dummy-value' : diagSettings.name
  scope: publicLoadBalancer
  properties: {
    workspaceId: empty(diagSettings.workspaceId) ? json('null') : diagSettings.workspaceId
    storageAccountId: empty(diagSettings.storageAccountId) ? json('null') : diagSettings.storageAccountId
    eventHubAuthorizationRuleId: empty(diagSettings.eventHubAuthorizationRuleId) ? json('null') : diagSettings.eventHubAuthorizationRuleId
    eventHubName: empty(diagSettings.eventHubName) ? json('null') : diagSettings.eventHubName

    logs: []
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
  name: '${lbName}-delete-lock'
  scope: publicLoadBalancer
  properties: {
    level: 'CanNotDelete'
    notes: 'Enabled as part of IaC Deployment'
  }
}
