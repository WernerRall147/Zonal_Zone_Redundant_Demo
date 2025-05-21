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

// Create NSGs
resource networkSecurityGroups 'Microsoft.Network/networkSecurityGroups@2023-05-01' = [for subnet in subnets: {
  name: subnet.nsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      // Default rules will be applied based on the subnet type
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
    ]
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
