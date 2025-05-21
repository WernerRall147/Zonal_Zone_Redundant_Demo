# Zonal vs. Zone-Redundant Azure Architecture Demo

This project demonstrates the architectural trade-offs between:
- **Zonal Deployment** (optimized for low latency)
- **Zone-Redundant Deployment** (optimized for high availability)

## Architecture Overview

This solution deploys a scaled-down representation of a financial services application with components similar to Nice Actimize across multiple Availability Zones (AZs) in Azure:

```
+-----------------------------------------------------------------------------------------------+
|                                     Azure Front Door                                          |
+-----------------------------------------------------------------------------------------------+
                /\                                               /\       /\        /\
                ||                                               ||       ||        ||
+--------------------------+                   +------------------+-------++---------+----------+
| Zonal Deployment         |                   | Zone-Redundant Deployment                      |
| (Optimized for Latency)  |                   | (Optimized for Availability)                   |
+--------------------------+                   +------------------------------------------------+
|                          |                   |                                                |
| +----------------------+ |                   | +------------+  +------------+  +------------+ |
| | Availability Zone 1  | |                   | | Zone 1     |  | Zone 2     |  | Zone 3     | |
| |                      | |                   | |            |  |            |  |            | |
| | [Proximity Group]    | |                   | |            |  |            |  |            | |
| | +-----------------+  | |                   | |+----------+|  |+----------+|  |+----------+| |
| | | App Gateway WAF |  | |                   | || App GW   ||  || App GW   ||  || App GW   || |
| | +-----------------+  | |                   | |+----------+|  |+----------+|  |+----------+| |
| |         |            | |                   | |     |      |  |     |      |  |     |      | |
| | +-----------------+  | |                   | |+----------+|  |+----------+|  |+----------+| |
| | | API Management  |  | |                   | || API Mgmt ||  || API Mgmt ||  || API Mgmt || |
| | +-----------------+  | |                   | |+----------+|  |+----------+|  |+----------+| |
| |       /   \          | |                   | |  /      \  |  |  /      \  |  |  /      \  | |
| | +------+  +------+   | |                   | |+-+      +-+|  |+-+      +-+|  |+-+      +-+| |
| | | App  |  | ESB  |   | |                   | ||A|      |E||  ||A|      |E||  ||A|      |E|| |
| | | VM   |  | VM   |   | |                   | ||p|      |S||  ||p|      |S||  ||p|      |S|| |
| | +------+  +------+   | |                   | ||p|      |B||  ||p|      |B||  ||p|      |B|| |
| |    |  \   /  |       | |                   | |+-+      +-+|  |+-+      +-+|  |+-+      +-+| |
| | +------+  +------+   | |                   | |+-+      +-+|  |+-+      +-+|  |+-+      +-+| |
| | | SQL  |  | Redis |  | |                   | ||S|      |R||  ||S|      |R||  ||S|      |R|| |
| | | DB   |  | Cache |  | |                   | ||Q|      |e||  ||Q|      |e||  ||Q|      |e|| |
| | +------+  +------+   | |                   | ||L|      |d||  ||L|      |d||  ||L|      |d|| |
| +----------------------+ |                   | |+-+      +-+|  |+-+      +-+|  |+-+      +-+| |
|                          |                   | +------------+  +------------+  +------------+ |
+--------------------------+                   +------------------------------------------------+
|                          |                   |                                                |
|   Azure Monitor + Log Analytics Workspace    |   Azure Monitor + Log Analytics Workspace      |
+--------------------------+-------------------+------------------------------------------------+

Trade-offs:
- Zonal: Lower latency (~1-2ms), single-zone resilience (99.9% SLA)
- Zone-Redundant: Higher availability (99.99% SLA), multi-zone resilience, higher latency (~3-5ms)
```

### Key Components
- **Azure Front Door** for global routing
- **Azure Application Gateway (WAF)** for web protection
- **API Management** for API traffic control
- **App Servers & ESB** deployed across AZs
- **SQL Database** (simulating Oracle DB with Data Guard)
- **Azure Cache for Redis** with geo-replication
- **Proximity Placement Groups (PPGs)** for intra-AZ latency optimization
- **Accelerated Networking** for VM performance

## Deployment Options

The solution can be deployed in either:

1. **Zonal Configuration**: Resources deployed in a single availability zone with proximity placement groups to optimize for low latency, sacrificing some availability.

2. **Zone-Redundant Configuration**: Resources deployed across multiple availability zones to optimize for high availability, with potentially higher latency between components.

## Prerequisites

- Azure subscription with quota for VMs, networking, and storage
- PowerShell 7.0+
- Azure PowerShell module (`Az`)
- Bicep CLI

### Pre-Flight Checklist

Before deployment, verify the following:

1. **Check your subscription quotas**:
   ```powershell
   # Check quota for VMs in the target region
   Get-AzVMUsage -Location "southafricanorth"
   
   # Check quota for Public IPs in the target region
   $provider = Get-AzResourceProvider -ProviderNamespace Microsoft.Network
   $quotas = Get-AzNetworkUsage -Location "southafricanorth"
   $quotas | Where-Object {$_.Name.Value -eq "PublicIPAddresses"}
   ```

2. **Verify Azure PowerShell installation**:
   ```powershell
   # Check Az module
   Get-InstalledModule -Name Az
   
   # Ensure you're using PowerShell 7+
   $PSVersionTable.PSVersion
   ```

3. **Verify Bicep CLI installation**:
   ```powershell
   # Check Bicep version
   bicep --version
   ```

4. **Verify your Azure permissions**:
   ```powershell
   # Login to Azure
   Connect-AzAccount
   
   # Check your role assignments
   Get-AzRoleAssignment -SignInName (Get-AzContext).Account.Id
   ```

5. **Check that the region supports availability zones**:
   - South Africa North has availability zone support
   - If using a different region, verify it supports availability zones:
   ```powershell
   Get-AzComputeResourceSku | Where-Object {$_.LocationInfo.Count -gt 0 -and $_.LocationInfo[0].Zones -ne $null}
   ```

## Deployment Instructions

1. Clone this repository to your local machine:
   ```
   git clone https://github.com/yourusername/Zonal_Zone_Redundant_Demo.git
   cd Zonal_Zone_Redundant_Demo
   ```

2. Connect to your Azure account:
   ```
   Connect-AzAccount
   ```

3. Run the deployment script:

   For **Zone-Redundant** (high availability) deployment:
   ```
   ./deploy.ps1 -ResourceGroupName "your-resource-group" -Location "southafricanorth" -IsZoneRedundant -AdminUsername "adminuser" -AdminPassword (ConvertTo-SecureString -String "YourComplexPassword123!" -AsPlainText -Force)
   ```

   For **Zonal** (low latency) deployment:
   ```
   ./deploy.ps1 -ResourceGroupName "your-resource-group" -Location "southafricanorth" -AdminUsername "adminuser" -AdminPassword (ConvertTo-SecureString -String "YourComplexPassword123!" -AsPlainText -Force)
   ```

   > **Note**: Replace "your-resource-group" and password with your desired values. The default location is South Africa North. Change if needed.

4. The script will validate the deployment using a what-if operation and then prompt for confirmation before proceeding.

## Measuring Performance vs. Availability Trade-offs

After deployment, you can measure and compare:

- **Latency**: Use Application Insights and the deployed monitoring dashboard to compare request latencies between the zonal and zone-redundant architectures.

- **Resilience**: Simulate failures by stopping VMs in specific zones and observe the behavior of both architectures.

- **Network Throughput**: Compare network performance between closely located resources (zonal) versus distributed resources (zone-redundant).

### Performance Testing

To test the deployment and compare performance metrics between the zonal and zone-redundant architectures, follow these steps:

#### 1. Testing Basic Connectivity

First, verify that all components are accessible:

```powershell
# Get the deployment outputs
$deployment = Get-AzResourceGroupDeployment -ResourceGroupName "your-resource-group" -Name "zonal-zone-redundant-demo"

# Test Front Door endpoint
$frontDoorUrl = "https://$($deployment.Outputs.frontDoorEndpoint.Value)"
Invoke-WebRequest -Uri $frontDoorUrl

# Test Application Gateway endpoint
$appGatewayIp = $deployment.Outputs.appGatewayPublicIp.Value
Invoke-WebRequest -Uri "http://$appGatewayIp"
```

#### 2. Measuring Latency

To measure request latency:

```powershell
# Function to test latency
function Test-Endpoint-Latency {
    param (
        [string]$Uri,
        [int]$Count = 10
    )
    
    $results = @()
    for ($i = 1; $i -le $Count; $i++) {
        $start = Get-Date
        try {
            $response = Invoke-WebRequest -Uri $Uri -TimeoutSec 30
            $end = Get-Date
            $latency = ($end - $start).TotalMilliseconds
            $results += $latency
            Write-Host "Request $i - Status: $($response.StatusCode), Latency: $($latency.ToString("0.00")) ms"
        } catch {
            Write-Host "Request $i - Failed: $_"
        }
        Start-Sleep -Milliseconds 500
    }
    
    if ($results.Count -gt 0) {
        $avg = ($results | Measure-Object -Average).Average
        $min = ($results | Measure-Object -Minimum).Minimum
        $max = ($results | Measure-Object -Maximum).Maximum
        
        Write-Host "Results:"
        Write-Host "  Average: $($avg.ToString("0.00")) ms"
        Write-Host "  Minimum: $($min.ToString("0.00")) ms"
        Write-Host "  Maximum: $($max.ToString("0.00")) ms"
    }
}

# Test Front Door latency
Write-Host "Testing Front Door latency..." -ForegroundColor Cyan
Test-Endpoint-Latency -Uri $frontDoorUrl

# Test App Gateway latency
Write-Host "Testing App Gateway latency..." -ForegroundColor Cyan
Test-Endpoint-Latency -Uri "http://$appGatewayIp"
```

#### 3. Checking Resource Distribution Across Zones

To verify resource distribution across availability zones:

```powershell
# Check VM distribution
Get-AzVM -ResourceGroupName "your-resource-group" | Format-Table Name, ResourceGroupName, @{label='Zones';expression={$_.Zones}}

# Check other zonal resources
Get-AzResource -ResourceGroupName "your-resource-group" | Where-Object {$_.Zones -ne $null} | Format-Table Name, ResourceType, @{label='Zones';expression={$_.Zones}}
```

#### 4. Testing Zone Failure Resilience (For Zone-Redundant Deployments)

To simulate a zone failure and test resilience:

```powershell
# Identify VMs in Zone 1
$zone1VMs = Get-AzVM -ResourceGroupName "your-resource-group" | Where-Object {$_.Zones -contains "1"}

# Stop all VMs in Zone 1 to simulate zone failure
$zone1VMs | Stop-AzVM -Force

# Test application functionality after zone failure
Invoke-WebRequest -Uri $frontDoorUrl

# Restart VMs when done testing
$zone1VMs | Start-AzVM
```

### Architecture Tradeoffs

| Aspect | Zonal Deployment | Zone-Redundant Deployment |
|--------|------------------|---------------------------|
| **Deployment Focus** | Performance (Low Latency) | Reliability (High Availability) |
| **Latency** | Lower (1-2ms between components) | Higher (3-5ms between zones) |
| **Availability SLA** | ~99.9% | ~99.99% |
| **Zone Failure Impact** | Complete outage | Degraded performance, but still operational |
| **Proximity Placement Groups** | Used to minimize latency | Not used (resources distributed across zones) |
| **Resource Usage** | Lower (fewer instances) | Higher (redundant instances) |
| **Ideal For** | Low-latency financial trading<br>Real-time data processing<br>Time-sensitive operations | Mission-critical applications<br>High-value financial systems<br>Systems requiring 24/7 uptime |

### Key Architectural Decisions

#### Zonal Architecture
- **Single Zone**: All resources in a single availability zone
- **Proximity Placement Group**: All VMs and supported services placed in PPG
- **Accelerated Networking**: Enabled on all VMs to minimize network latency
- **Optimized VM Sizes**: Memory-optimized VM sizes for data processing

#### Zone-Redundant Architecture
- **Multiple Zones**: Resources distributed across three availability zones
- **Load Balancing**: Traffic distributed across zones based on health and load
- **Redundant Components**: Each component has replicas in different zones
- **Cross-Zone Replication**: Data continuously synchronized between zones

## Clean Up Resources

When you're done with the demo, delete the resource group to avoid incurring additional costs:

```powershell
Remove-AzResourceGroup -Name "your-resource-group" -Force
```

## Contributing

Contributions to improve the demo are welcome. Please feel free to submit a pull request.

## Implementation Details

### Module Structure

This project uses a modular Bicep structure to promote reusability and maintainability:

- `main.bicep` - Orchestrates the deployment of all modules
- `/modules/` - Contains the following modules:
  - `network.bicep` - VNet, subnets, NSGs, and route tables
  - `proximitygroups.bicep` - Proximity placement groups for low-latency configuration
  - `appgateway.bicep` - Application Gateway with WAF configuration
  - `apim.bicep` - API Management service
  - `compute.bicep` - App and ESB VMs with accelerated networking
  - `database.bicep` - SQL Database (simulating Oracle with Data Guard)
  - `redis.bicep` - Redis Cache with zone-redundancy options
  - `frontdoor.bicep` - Azure Front Door for global routing
  - `monitoring.bicep` - Azure Monitor and Log Analytics

### Configuration Parameters

Each module accepts a standard set of parameters:
- `location` - Azure region
- `resourceToken` - Naming convention token
- `tags` - Resource tagging
- `isZoneRedundant` - Boolean toggle to switch between deployment modes

### Testing Failover

To test the zone-redundant deployment's resilience:

1. Deploy the zone-redundant configuration
2. Test the application to ensure it's working properly
3. Simulate a zone outage by stopping all VMs in one zone:
   ```powershell
   # List VMs by zone
   Get-AzVM -ResourceGroupName "your-resource-group" | Format-Table Name, ResourceGroupName, @{label='Zones';expression={$_.Zones}}
   
   # Stop all VMs in Zone 1 to simulate zone failure
   Get-AzVM -ResourceGroupName "your-resource-group" | Where-Object {$_.Zones -contains "1"} | Stop-AzVM -Force
   ```
4. Verify that the application continues to function with minimal disruption
5. Restart the VMs to simulate zone recovery

## License

This project is licensed under the MIT License - see the LICENSE file for details.
