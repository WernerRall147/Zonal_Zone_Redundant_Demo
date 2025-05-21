// Application Gateway (WAF) module for Zonal vs Zone-Redundant demo
// Deploys Application Gateway with WAF to protect web layer

// Parameters
@description('Location for all resources')
param location string

@description('Resource name token')
param resourceToken string

@description('Tags to apply to all resources')
param tags object

@description('Virtual network name')
param vnetName string

@description('Subnet name for the Application Gateway')
param subnetName string

@description('Deploy in zone-redundant mode if true, or zonal if false')
param isZoneRedundant bool

@description('Availability zones to deploy resources in')
param availabilityZones array = [
  '1'
  '2'
  '3'
]

// Variables
var appGatewayName = '${resourceToken}-appgw'
var appGatewayPipName = '${resourceToken}-appgw-pip'
var subnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)

// Public IP for Application Gateway
resource appGatewayPublicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: appGatewayPipName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: resourceToken
    }
  }
  // Apply zones based on deployment type
  zones: isZoneRedundant ? availabilityZones : [availabilityZones[0]]
}

// Application Gateway (WAF)
resource appGateway 'Microsoft.Network/applicationGateways@2023-05-01' = {
  name: appGatewayName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      // Zone-redundant architecture will distribute capacity across zones
      // Zonal architecture will use a single instance in a single zone for low latency
      capacity: isZoneRedundant ? 3 : 1
    }
    gatewayIPConfigurations: [
      {
        name: 'appGwIpConfig'
        properties: {
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwFrontendIP'
        properties: {
          publicIPAddress: {
            id: appGatewayPublicIp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'defaultBackendPool'
        properties: {
          backendAddresses: []
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'defaultHttpSettings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 20
        }
      }
    ]
    httpListeners: [
      {
        name: 'defaultListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGatewayName, 'appGwFrontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName, 'port_80')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'defaultRule'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGatewayName, 'defaultListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGatewayName, 'defaultBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGatewayName, 'defaultHttpSettings')
          }
        }
      }
    ]
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Prevention'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.2'
    }
  }
  // Apply zones based on deployment type
  zones: isZoneRedundant ? availabilityZones : [availabilityZones[0]]
}

// Outputs
output appGatewayId string = appGateway.id
output appGatewayName string = appGateway.name
output appGatewayPublicIp string = appGatewayPublicIp.properties.ipAddress
output appGatewayHostName string = appGatewayPublicIp.properties.dnsSettings.fqdn
