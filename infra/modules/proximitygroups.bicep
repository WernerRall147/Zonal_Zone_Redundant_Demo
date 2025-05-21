// Proximity Placement Groups module for Zonal vs Zone-Redundant demo
// Creates proximity placement groups for each availability zone
// to optimize intra-zone latency

// Parameters
@description('Location for all resources')
param location string

@description('Resource name token')
param resourceToken string

@description('Tags for all resources')
param tags object

@description('Availability zones to deploy resources in')
param availabilityZones array = [
  '1'
  '2'
  '3'
]

// Create Proximity Placement Groups (one per zone)
resource proximityPlacementGroups 'Microsoft.Compute/proximityPlacementGroups@2023-07-01' = [for zone in availabilityZones: {
  name: '${resourceToken}-ppg-zone-${zone}'
  location: location
  tags: tags
  properties: {
    proximityPlacementGroupType: 'Standard'
    // Zone redundant architecture will not use proximity placement groups
    // but we're still creating them for demonstration/comparison
  }
}]

// Outputs
output proximityPlacementGroupIds array = [for i in range(0, length(availabilityZones)): {
  zone: availabilityZones[i]
  id: proximityPlacementGroups[i].id
}]

// Output first zone's PPG ID for use with zonal deployments
output proximityPlacementGroupId string = proximityPlacementGroups[0].id
