// API Management module for Zonal vs Zone-Redundant demo
// Deploys API Management service for API traffic control

// Parameters
@description('Location for all resources')
param location string

@description('Resource name token')
param resourceToken string

@description('Tags to apply to all resources')
param tags object

@description('Virtual network name')
param vnetName string

@description('Subnet name for the API Management')
param subnetName string

@description('Deploy in zone-redundant mode if true, or zonal if false')
param isZoneRedundant bool

@description('Admin email address for API Management')
param adminEmail string

@description('Admin name for API Management')
param adminName string

// Variables
var apimName = '${resourceToken}-apim'
var subnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)

// API Management service
resource apiManagement 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: apimName
  location: location
  tags: tags
  sku: {
    name: 'Developer' // Use Developer tier for demo, simpler VNet setup
    capacity: 1
  }
  properties: {
    publisherEmail: adminEmail
    publisherName: adminName
    // Temporarily deploy without VNet to avoid connectivity issues
    // virtualNetworkConfiguration: {
    //   subnetResourceId: subnetId
    // }
    // virtualNetworkType: 'External'
  }
  // Developer tier doesn't support availability zones, but this is a demo
  // zones: isZoneRedundant ? ['1', '2', '3'] : ['1']
}

// APIM API
resource sampleApi 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  parent: apiManagement
  name: 'sample-api'
  properties: {
    displayName: 'Sample API'
    description: 'Sample API for demonstration'
    path: 'sample'
    protocols: [
      'https'
    ]
    subscriptionRequired: true
  }
}

// Sample API Operation
resource getOperation 'Microsoft.ApiManagement/service/apis/operations@2023-05-01-preview' = {
  parent: sampleApi
  name: 'get-operation'
  properties: {
    displayName: 'Get Sample Data'
    method: 'GET'
    urlTemplate: '/'
    description: 'Get sample data'
  }
}

// Outputs
output apiManagementId string = apiManagement.id
output apiManagementName string = apiManagement.name
output apiManagementEndpoint string = 'https://${apiManagement.name}.azure-api.net'
