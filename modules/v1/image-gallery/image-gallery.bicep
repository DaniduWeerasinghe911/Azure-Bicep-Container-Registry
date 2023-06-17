
@description('The name of the resource.')
param imageGalleryName string

@description('Location of the resource.')
param location string

@description('Resource Objects.')
param tags object = {}

@description('Resource Description')
param rDescription string

@description('Resource Description')
param isSoftDeleteEnabled bool = false

resource imageGallery 'Microsoft.Compute/galleries@2022-01-03' = {
  name: imageGalleryName
  location: location
  tags: tags
  properties: {
    description: rDescription
    identifier: {}
//    softDeletePolicy: {
//      isSoftDeleteEnabled: isSoftDeleteEnabled
 //   }
  }
}

output imageGalleryName string = imageGallery.name
