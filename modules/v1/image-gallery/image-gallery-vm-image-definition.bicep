 
@description('The name of the resource.')
param imageGalleryName string

@description('Location of the resource.')
param location string

@description('Location of the resource.')
param hyperVGeneration string = 'V1'


@description('Detailed image information to set for the custom image produced by the Azure Image Builder build.')
param imageDefinitionProperties object


resource imageDefinition 'Microsoft.Compute/galleries/images@2020-09-30' = {
  name: '${imageGalleryName}/${imageDefinitionProperties.name}'
  location: location
  properties: {
    osType: 'Windows'
    osState: 'Generalized'
    identifier: {
      publisher: imageDefinitionProperties.publisher
      offer: imageDefinitionProperties.offer
      sku: imageDefinitionProperties.sku
    }
    recommended: {
      vCPUs: {
        min: 2
        max: 8
      }
      memory: {
        min: 16
        max: 48
      }
    }
    hyperVGeneration: hyperVGeneration
  }
}
