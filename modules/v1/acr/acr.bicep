@description('ACR Name')
param acrName string

@description('Location Name')
param location string

@description('SKU Name')
@allowed(
  [
    'Standard'
    'Premium'
    'Classic'
    'Basic'
  ]

)
param skuName string = 'Basic'

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: skuName
  }
}

