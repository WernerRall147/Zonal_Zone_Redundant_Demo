// Database module for Zonal vs Zone-Redundant demo
// Deploys SQL Database with failover (simulating Oracle with Data Guard)

// Parameters
@description('Location for all resources')
param location string

@description('Resource name token')
param resourceToken string

@description('Tags to apply to all resources')
param tags object

@description('Virtual network name')
param vnetName string

@description('Subnet name for the database resources')
param subnetName string

@description('Admin username for database')
@secure()
param adminUsername string

@description('Admin password for database')
@secure()
param adminPassword string

@description('Deploy in zone-redundant mode if true, or zonal if false')
param isZoneRedundant bool

// @description('Availability zones to deploy resources in')  // Currently unused, commenting out
// param availabilityZones array = [
//   '1'
//   '2' 
//   '3'
// ]

// Variables
var sqlServerName = '${resourceToken}-sql'
var sqlDatabaseName = '${resourceToken}-db'
var subnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)

// Private DNS Zone for SQL Server
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink${environment().suffixes.sqlServerHostname}'
  location: 'global'
  tags: tags
}

// Link the Private DNS Zone to the VNet
resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${resourceToken}-link'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', vnetName)
    }
  }
}

// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags
  properties: {
    administratorLogin: adminUsername
    administratorLoginPassword: adminPassword
    version: '12.0'
    publicNetworkAccess: 'Disabled'
    minimalTlsVersion: '1.2'
  }
}

// Private Endpoint for SQL Server
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: '${resourceToken}-sql-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${resourceToken}-sql-plsc'
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
  }
}

// Private DNS Zone Group
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

// SQL Database - Configure zone redundancy based on parameter
resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  tags: tags
  sku: {
    name: 'Premium'
    tier: 'Premium'
    // For demo purposes - in production would use BusinessCritical tier
    capacity: isZoneRedundant ? 125 : 125
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 1073741824 // 1GB
    // Zone redundancy for high availability
    zoneRedundant: isZoneRedundant
    // Basic backup configuration
    requestedBackupStorageRedundancy: isZoneRedundant ? 'Zone' : 'Local'
  }
}

// For a failover group (simulating Data Guard)
resource failoverGroup 'Microsoft.Sql/servers/failoverGroups@2023-05-01-preview' = if (isZoneRedundant) {
  parent: sqlServer
  name: '${resourceToken}-fog'
  properties: {
    readWriteEndpoint: {
      failoverPolicy: 'Automatic'
      failoverWithDataLossGracePeriodMinutes: 60
    }
    readOnlyEndpoint: {
      failoverPolicy: 'Disabled'
    }
    partnerServers: [] // In a real setup, would add a secondary server
    databases: [
      sqlDatabase.id
    ]
  }
}

// Outputs
output sqlServerName string = sqlServer.name
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output sqlDatabaseName string = sqlDatabase.name
output failoverGroupId string = isZoneRedundant ? failoverGroup.id : 'Not deployed in zonal configuration'
