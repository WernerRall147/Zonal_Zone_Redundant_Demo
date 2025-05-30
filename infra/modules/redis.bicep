// Redis Cache module for Zonal vs Zone-Redundant demo
// Deploys Azure Cache for Redis with geo-replication

// Parameters
@description('Location for all resources')
param location string

@description('Resource name token')
param resourceToken string

@description('Tags to apply to all resources')
param tags object

@description('Deploy in zone-redundant mode if true, or zonal if false')
param isZoneRedundant bool

@description('Availability zones to deploy resources in')
param availabilityZones array = [
  '1'
  '2'
  '3'
]

// Variables
var redisName = '${resourceToken}-redis'

// Redis Cache
resource redisCache 'Microsoft.Cache/redis@2024-03-01' = {
  name: redisName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'Premium'
      family: 'P'
      capacity: isZoneRedundant ? 2 : 1
    }
    enableNonSslPort: false
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    redisConfiguration: {
      'maxmemory-policy': 'allkeys-lru'
    }
  }
  zones: isZoneRedundant ? availabilityZones : [availabilityZones[0]]
}

// Redis Cache Firewall Rules
resource redisFirewallRule 'Microsoft.Cache/redis/firewallRules@2024-03-01' = {
  parent: redisCache
  name: 'AllowAll'
  properties: {
    startIP: '0.0.0.0'
    endIP: '255.255.255.255'
  }
}

// Outputs
output redisCacheId string = redisCache.id
output redisCacheName string = redisCache.name
output redisCacheHostName string = redisCache.properties.hostName
