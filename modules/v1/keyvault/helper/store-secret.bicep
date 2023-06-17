// Helper bicep specifically for storing a secret in a Key Vault

@description('Name of the Key Vault')
param keyVaultName string

@description('Name of the Secret')
param secretName string

@description('Value of the Secret')
@secure()
param secretValue string

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: keyVaultName
  resource secret 'secrets' = {
    name: secretName
    properties: {
      value: secretValue
    }
  }
}
