# Set variables
$subscriptionId = "cef2460d-0ed3-4c43-ab44-2efa10dd34bb"
$basePath = ".\modules"
$bicepFileExtension = ".bicep"
$acrLoginServer = "dckloudacr.azurecr.io"

# Connect to Azure
Connect-AzAccount

# Select Azure subscription
Set-AzContext -SubscriptionId $subscriptionId

# Get the list of Bicep files in the base path
$bicepFiles = Get-ChildItem -Path $basePath -Filter "*$bicepFileExtension" -Recurse

# Loop through each Bicep file
foreach ($bicepFile in $bicepFiles) {
    # Publish Bicep module
    $bicepFilePath = $bicepFile.FullName
    Write-Host "Publishing Bicep module: $bicepFilePath..."

    # Extract version and module name from the file path
    $version = (Split-Path $bicepFile.Directory.Parent.FullName -Leaf)
    $module = (Split-Path $bicepFile.Directory.FullName -Leaf)

    $imageName = $module
    $imageTag = $version
    $dockerImage = "br:${acrLoginServer}/bicep/modules/${imageName}:${imageTag}"

    Publish-AzBicepModule -FilePath $bicepFilePath -Target $dockerImage

    Write-Host "Bicep module published successfully: $bicepFilePath"
}
