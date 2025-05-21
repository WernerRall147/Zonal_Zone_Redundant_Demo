// Front Door module for Zonal vs Zone-Redundant demo
// Deploys Azure Front Door for global routing and WAF protection

// Parameters
@description('Location for all resources - uses global for Front Door')
param location string = 'global'

@description('Resource name token')
param resourceToken string

@description('Tags to apply to all resources')
param tags object

@description('Hostname of the Application Gateway')
param appGatewayHostName string

// Variables
var frontDoorName = '${resourceToken}-fd'
var frontDoorEndpointName = '${resourceToken}-endpoint'
var frontDoorOriginGroupName = '${resourceToken}-origin-group'
var frontDoorOriginName = '${resourceToken}-origin'
var frontDoorRouteName = '${resourceToken}-route'

// Front Door Profile (Standard tier with WAF)
resource frontDoorProfile 'Microsoft.Cdn/profiles@2023-05-01' = {
  name: frontDoorName
  location: location
  tags: tags
  sku: {
    name: 'Standard_AzureFrontDoor'
  }
}

// Front Door Endpoint
resource frontDoorEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2023-05-01' = {
  parent: frontDoorProfile
  name: frontDoorEndpointName
  location: location
  tags: tags
  properties: {
    enabledState: 'Enabled'
  }
}

// Front Door Origin Group
resource frontDoorOriginGroup 'Microsoft.Cdn/profiles/originGroups@2023-05-01' = {
  parent: frontDoorProfile
  name: frontDoorOriginGroupName
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 50
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Http'
      probeIntervalInSeconds: 100
    }
  }
}

// Front Door Origin (pointing to the App Gateway)
resource frontDoorOrigin 'Microsoft.Cdn/profiles/originGroups/origins@2023-05-01' = {
  parent: frontDoorOriginGroup
  name: frontDoorOriginName
  properties: {
    hostName: appGatewayHostName
    httpPort: 80
    httpsPort: 443
    originHostHeader: appGatewayHostName
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
  }
}

// Front Door Route
resource frontDoorRoute 'Microsoft.Cdn/profiles/afdEndpoints/routes@2023-05-01' = {
  parent: frontDoorEndpoint
  name: frontDoorRouteName
  properties: {
    originGroup: {
      id: frontDoorOriginGroup.id
    }
    originPath: '/'
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpsOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
  }
}

// Outputs
output frontDoorId string = frontDoorProfile.id
output frontDoorEndpoint string = frontDoorEndpoint.properties.hostName
