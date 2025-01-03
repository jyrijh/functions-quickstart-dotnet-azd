// Parameters
@description('Specifies the name of the virtual network.')
param virtualNetworkName string

@description('Specifies the name of the subnet which contains the virtual machine.')
param subnetName string

@description('Specifies the resource name of the cache resource with an endpoint.')
param resourceName string

@description('Specifies the location.')
param location string = resourceGroup().location

param tags object = {}

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: virtualNetworkName
}

resource redisCache 'Microsoft.Cache/redis@2023-08-01' existing = {
  name: resourceName
}

var cachePrivateDNSZoneName = 'privatelink.redis.cache.windows.net'
var cachePrivateDnsZoneVirtualNetworkLinkName = 'privatelink.redis.cache.azure.net-applink'

resource cachePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'cache-private-endpoint'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'cachePrivateLinkConnection'
        properties: {
          privateLinkServiceId: redisCache.id
          groupIds: [
            'redisCache'
          ]
        }
      }
    ]
    subnet: {
      id: '${vnet.id}/subnets/${subnetName}'
    }
  }
}

resource cachePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: cachePrivateDNSZoneName
  location: 'global'
  tags: tags
}

resource privateDnsZoneLinkCache 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: cachePrivateDnsZone
  name: cachePrivateDnsZoneVirtualNetworkLinkName
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource cachePvtEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-01-01' = {
  parent: cachePrivateEndpoint
  name: 'cachePrivateDnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-redis-cache-windows-net'
        properties: {
          privateDnsZoneId: cachePrivateDnsZone.id
        }
      }
    ]
  }
  dependsOn: [
    privateDnsZoneLinkCache
  ]
}
