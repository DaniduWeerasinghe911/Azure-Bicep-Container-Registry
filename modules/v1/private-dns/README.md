# Private DNS

This module contains the following capabilities:

- `private-link-dns-zones`: Create Private DNS Zones for the purposes of Private Link.  Leaving param blank will do a full list of known zones.

- `private-dns-vnet-link`: Link a Private DNS Zone to a VNET

## Usage

### Example 1 - Create a set of Private DNS Zones used for Private Link

``` bicep
module private_dns './private-link-dns-zones.bicep' = {
  name: 'deploy_private_dns'
  params: {
    dnsZoneList: [
      'privatelink.database.windows.net'
      'privatelink.blob.core.windows.net'
      'privatelink.table.core.windows.net'
      'privatelink.queue.core.windows.net'
      'privatelink.file.core.windows.net'
      'privatelink.vaultcore.azure.net'
      'privatelink.azurecr.io'
    ]
  }
}
```

### Example 2 - Link Private DNS Zones to an existing VNET

``` bicep
module link_private_dns './private-dns-vnet-link.bicep' = {
  name: 'deploy_private_dns_links'
  params: {
    dnsZoneList = [
      'privatelink.database.windows.net'
      'privatelink.blob.core.windows.net'
      'privatelink.table.core.windows.net'
      'privatelink.queue.core.windows.net'
      'privatelink.file.core.windows.net'
      'privatelink.vaultcore.azure.net'
      'privatelink.azurecr.io'
    ]
    linkPrefix = 'example-'
    vnetId = '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourcegroups/example-dev-rg/providers/Microsoft.Network/virtualNetworks/example-dev-vnet'
  }
}
```
