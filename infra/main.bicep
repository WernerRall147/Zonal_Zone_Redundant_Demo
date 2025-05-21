// Zonal vs. Zone-Redundant Azure Deployment
// Main Bicep template to demonstrate tradeoffs between low latency (zonal) and high availability (zone-redundant)

@description('Location for all resources')
param location string = resourceGroup().location

@description('Environment name')
param envName string = 'demo'

@description('Prefix to use for resource naming')
param prefix string = 'azzzr'

@description('Deploys resources in zone-redundant configuration if true, or zonal configuration if false')
param isZoneRedundant bool = true

@description('Admin username for VMs and databases')
@secure()
param adminUsername string 

@description('Admin password for VMs and databases')
@secure()
param adminPassword string

// Variables
var resourceToken = '${prefix}-${envName}'
var tags = {
  Environment: envName
  Project: 'Zonal-Zone-Redundant-Demo'
  DeploymentType: isZoneRedundant ? 'Zone-Redundant' : 'Zonal'
}

// Deploy Network
module networkModule 'modules/network.bicep' = {
  name: 'networkDeployment'
  params: {
    location: location
    resourceToken: resourceToken
    tags: tags
  }
}

// Deploy Proximity Placement Groups (for zonal deployments)
module proximityModule 'modules/proximitygroups.bicep' = {
  name: 'proximityDeployment'
  params: {
    location: location
    resourceToken: resourceToken
    tags: tags
    isZoneRedundant: isZoneRedundant
  }
}

// Deploy Application Gateway
module appGatewayModule 'modules/appgateway.bicep' = {
  name: 'appGatewayDeployment'
  params: {
    location: location
    resourceToken: resourceToken
    tags: tags
    isZoneRedundant: isZoneRedundant
    appGatewaySubnetId: networkModule.outputs.appGatewaySubnetId
  }
}

// Deploy API Management
module apimModule 'modules/apim.bicep' = {
  name: 'apimDeployment' 
  params: {
    location: location
    resourceToken: resourceToken
    tags: tags
    isZoneRedundant: isZoneRedundant
    apiManagementSubnetId: networkModule.outputs.apiManagementSubnetId
  }
}

// Deploy Redis Cache
module redisModule 'modules/redis.bicep' = {
  name: 'redisDeployment'
  params: {
    location: location
    resourceToken: resourceToken
    tags: tags
    isZoneRedundant: isZoneRedundant
  }
}

// Deploy Database
module dbModule 'modules/database.bicep' = {
  name: 'dbDeployment'
  params: {
    location: location
    resourceToken: resourceToken
    tags: tags
    isZoneRedundant: isZoneRedundant
    adminUsername: adminUsername
    adminPassword: adminPassword
    dbSubnetId: networkModule.outputs.dbSubnetId
  }
}

// Deploy Compute (App and ESB VMs)
module computeModule 'modules/compute.bicep' = {
  name: 'computeDeployment'
  params: {
    location: location
    resourceToken: resourceToken
    tags: tags
    isZoneRedundant: isZoneRedundant
    appSubnetId: networkModule.outputs.appSubnetId
    proximityPlacementGroupId: isZoneRedundant ? '' : proximityModule.outputs.proximityPlacementGroupId
    adminUsername: adminUsername
    adminPassword: adminPassword
  }
}

// Deploy Front Door
module frontDoorModule 'modules/frontdoor.bicep' = {
  name: 'frontDoorDeployment'
  params: {
    location: location
    resourceToken: resourceToken
    tags: tags
    appGatewayHostName: appGatewayModule.outputs.appGatewayHostName
  }
}

// Deploy Monitoring
module monitoringModule 'modules/monitoring.bicep' = {
  name: 'monitoringDeployment'
  params: {
    location: location
    resourceToken: resourceToken
    tags: tags
  }
}

// Outputs
output resourceToken string = resourceToken
output frontDoorEndpoint string = frontDoorModule.outputs.frontDoorEndpoint
output appGatewayPublicIp string = appGatewayModule.outputs.appGatewayPublicIp
output apiManagementEndpoint string = apimModule.outputs.apiManagementEndpoint
output redisCacheHostName string = redisModule.outputs.redisCacheHostName
output sqlServerFqdn string = dbModule.outputs.sqlServerFqdn
output monitoringWorkspaceName string = monitoringModule.outputs.workspaceName
output deploymentType string = isZoneRedundant ? 'Zone-Redundant (High Availability)' : 'Zonal (Low Latency)'
