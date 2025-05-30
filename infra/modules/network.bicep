// Networking module for Zonal vs. Zone-Redundant demo
// Creates VNet, subnets, NSGs, and route tables

// Parameters
@description('Location for all resources')
param location string

@description('Resource name token')
param resourceToken string

@description('Tags to apply to all resources')
param tags object

// Variables
var vnetName = '${resourceToken}-vnet'
var vnetAddressPrefix = '10.0.0.0/16'

var subnets = [
  {
    name: 'app-gateway-subnet'
    addressPrefix: '10.0.0.0/24'
    nsgName: '${resourceToken}-appgw-nsg'
    routeTableName: '${resourceToken}-appgw-rt'
  }
  {
    name: 'api-management-subnet'
    addressPrefix: '10.0.1.0/24'
    nsgName: '${resourceToken}-apim-nsg'
    routeTableName: '${resourceToken}-apim-rt'
  }
  {
    name: 'app-subnet'
    addressPrefix: '10.0.2.0/24'
    nsgName: '${resourceToken}-app-nsg'
    routeTableName: '${resourceToken}-app-rt'
  }
  {
    name: 'db-subnet'
    addressPrefix: '10.0.3.0/24'
    nsgName: '${resourceToken}-db-nsg'
    routeTableName: '${resourceToken}-db-rt'
  }
]

// Create NSGs with subnet-specific rules
resource networkSecurityGroups 'Microsoft.Network/networkSecurityGroups@2023-05-01' = [for (subnet, i) in subnets: {
  name: subnet.nsgName
  location: location
  tags: tags
  properties: {
    securityRules: concat([
      // Default rules for all subnets
      {
        name: 'AllowInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '*'
          description: 'Allow all inbound traffic from VNet'
        }
      }
      // Application Gateway v2 management ports (for app gateway subnet)
      {
        name: 'AllowGatewayManager'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'GatewayManager'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '65200-65535'
          description: 'Allow Application Gateway management traffic'
        }
      }
    ], 
    // APIM-specific rules for apim-subnet (index 1)
    i == 1 ? [
      {
        name: 'AllowAPIMManagement'
        properties: {
          priority: 120
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'ApiManagement'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '3443'
          description: 'Allow APIM management endpoint'
        }
      }
      {
        name: 'AllowAPIMLoadBalancer'
        properties: {
          priority: 130
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '6381-6383'
          description: 'Allow APIM load balancer'
        }
      }
      {
        name: 'AllowAPIMTraffic'
        properties: {
          priority: 140
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '80'
          description: 'Allow HTTP traffic to APIM'
        }
      }
      {
        name: 'AllowAPIMTrafficTLS'
        properties: {
          priority: 150
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '443'
          description: 'Allow HTTPS traffic to APIM'
        }
      }
    ] : [])
  }
}]

// Create Route Tables
resource routeTables 'Microsoft.Network/routeTables@2023-05-01' = [for subnet in subnets: {
  name: subnet.routeTableName
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: false
  }
}]

// Create Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [for (subnet, i) in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        networkSecurityGroup: {
          id: networkSecurityGroups[i].id
        }
        routeTable: {
          id: routeTables[i].id
        }
      }
    }]
  }
}

// Outputs
output vnetName string = vnet.name
output vnetId string = vnet.id
output appGatewaySubnetName string = subnets[0].name
output appGatewaySubnetId string = '${vnet.id}/subnets/${subnets[0].name}'
output apiManagementSubnetName string = subnets[1].name
output apiManagementSubnetId string = '${vnet.id}/subnets/${subnets[1].name}'
output appSubnetName string = subnets[2].name
output appSubnetId string = '${vnet.id}/subnets/${subnets[2].name}'
output dbSubnetName string = subnets[3].name
output dbSubnetId string = '${vnet.id}/subnets/${subnets[3].name}'
