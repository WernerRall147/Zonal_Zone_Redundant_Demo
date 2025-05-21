// Compute module for Zonal vs Zone-Redundant demo
// Deploys App Servers & ESB VMs across specified availability zones

// Parameters
@description('Location for all resources')
param location string

@description('Resource name token')
param resourceToken string

@description('Tags to apply to all resources')
param tags object

@description('Virtual network name')
param vnetName string

@description('Subnet name for the compute resources')
param subnetName string

@description('Admin username for VMs')
@secure()
param adminUsername string

@description('Admin password for VMs')
@secure()
param adminPassword string

@description('Proximity placement group IDs for each zone')
param proximityPlacementGroupIds array

@description('Deploy in zone-redundant mode if true, or zonal if false')
param isZoneRedundant bool

@description('Availability zones to deploy resources in')
param availabilityZones array = [
  '1'
  '2'
  '3'
]

// Variables
var subnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
var vmSize = 'Standard_D4s_v3'
var appServers = [for i in range(0, isZoneRedundant ? 3 : 1): {
  name: '${resourceToken}-app-${i + 1}'
  zone: availabilityZones[i % length(availabilityZones)]
  ppgId: proximityPlacementGroupIds[i % length(proximityPlacementGroupIds)].id
  role: 'app'
}]
var esbServers = [for i in range(0, isZoneRedundant ? 3 : 1): {
  name: '${resourceToken}-esb-${i + 1}'
  zone: availabilityZones[i % length(availabilityZones)]
  ppgId: proximityPlacementGroupIds[i % length(proximityPlacementGroupIds)].id
  role: 'esb'
}]
var allVMs = concat(appServers, esbServers)

// NICs for VMs
resource networkInterfaces 'Microsoft.Network/networkInterfaces@2023-05-01' = [for (vm, i) in allVMs: {
  name: '${vm.name}-nic'
  location: location
  tags: tags
  properties: {
    enableAcceleratedNetworking: true // Enable accelerated networking for performance
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}]

// Virtual Machines
resource virtualMachines 'Microsoft.Compute/virtualMachines@2023-07-01' = [for (vm, i) in allVMs: {
  name: vm.name
  location: location
  tags: union(tags, {
    Role: vm.role
  })
  properties: {
    // Use proximity placement group in zonal deployment for low latency
    // Zone-redundant architecture will not use PPGs
    proximityPlacementGroup: isZoneRedundant ? null : {
      id: vm.ppgId
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaces[i].id
        }
      ]
    }
    osProfile: {
      computerName: vm.name
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
  }
  zones: [
    vm.zone
  ]
}]

// Custom script extension to install software
resource vmExtensions 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = [for (vm, i) in allVMs: {
  name: '${vm.name}/CustomScript'
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      // Use inline scripts instead of file loading
      script: vm.role == 'app' 
        ? base64('#!/bin/bash\necho "Setting up App server"\napt-get update\napt-get install -y nginx\necho "App server setup complete" > /tmp/setup-complete.log')
        : base64('#!/bin/bash\necho "Setting up ESB server"\napt-get update\napt-get install -y redis-server\necho "ESB server setup complete" > /tmp/setup-complete.log')
    }
    protectedSettings: {}
  }
  dependsOn: [
    virtualMachines[i]
  ]
}]

// Outputs
output vmIds array = [for (vm, i) in allVMs: {
  name: virtualMachines[i].name
  id: virtualMachines[i].id
  privateIp: networkInterfaces[i].properties.ipConfigurations[0].properties.privateIPAddress
  role: vm.role
  zone: vm.zone
}]
