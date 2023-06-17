@description('Name of the Virtual Machine')
param vmName string

@description('Script to Run')
param script string

@description('Script to Run')
@secure()
param runAsPassword string = ''
@description('Script to Run')
@secure()
param runAsUser string = ''

var name = '${vmName}/RunCommand'

resource runCommand 'Microsoft.Compute/virtualMachines/runCommands@2021-07-01' = {
  name: name
  location: resourceGroup().location
  properties: {
    asyncExecution: true
    source: {
      script: script
    }
    timeoutInSeconds: 300
    runAsPassword: empty(runAsPassword) ? json('null') : runAsPassword
    runAsUser: empty(runAsUser) ? json('null') : runAsUser 
  }
}
