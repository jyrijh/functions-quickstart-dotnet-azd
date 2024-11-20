param name string
param location string = resourceGroup().location

resource redisCache 'Microsoft.Cache/redis@2023-08-01' = {
  name: name
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

