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

// resource redisCache 'Microsoft.Cache/redis@2023-08-01' existing = {
//   name: resourceName
// }

var cachePrivateDNSZoneName = 'privatelink.redis.cache.azure.net' //format('privatelink.redis.{0}', environment().suffixes.storage)
var cachePrivateDnsZoneVirtualNetworkLinkName = 'privatelink.redis.cache.azure.net-applink' //format('{0}-link-{1}', resourceName, take(toLower(uniqueString(resourceName, virtualNetworkName)), 4))

resource cachePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: cachePrivateDNSZoneName
  location: 'global'
  tags: tags
  dependsOn:[
    vnet
    redisCache // If not here we get: "Deployment Error Details: ResourceNotFound"
  ]
}

resource privateDnsZoneLinkCache 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: cachePrivateDnsZone
  name: cachePrivateDnsZoneVirtualNetworkLinkName
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource cachePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'cache-private-endpoint' //cachePrivateEndpointName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'cachePrivateLinkConnection' //cachePrivateEndpointName
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
  dependsOn: [
    cachePrivateDnsZone
    privateDnsZoneLinkCache
  ]
}

resource cachePvtEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-01-01' = {
  parent: cachePrivateEndpoint
  name: 'cachePrivateDnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'cacheARecord'
        properties: {
          privateDnsZoneId: cachePrivateDnsZone.id
        }
      }
    ]
  }
}

resource redisCache 'Microsoft.Cache/redis@2023-08-01' = {
  name: resourceName
  location:location
  properties:{
    sku:{
      capacity: 0
      family: 'C'
      name: 'Basic'
    }
    enableNonSslPort:false
    redisVersion:'6'
    publicNetworkAccess:'Enabled'
  }
}
