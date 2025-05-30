# High Availability Demo Script
## Zonal vs Zone-Redundant Architecture Comparison

### Pre-Demo Setup
```powershell
# Set variables
$resourceGroup = "zonal-demo-rg"
$location = "southafricanorth"
```

### Part 1: Architecture Overview
**Show the deployment differences:**

```powershell
# Show current deployment mode
az deployment group show --resource-group $resourceGroup --name "zonal-deployment" --query "properties.parameters.isZoneRedundant.value"

# List all VMs and their zones
az vm list --resource-group $resourceGroup --query "[].{Name:name, Zone:zones[0], Size:hardwareProfile.vmSize}" --output table
```

### Part 2: Application Gateway High Availability
**Demonstrate load balancing and health monitoring:**

```powershell
# Show Application Gateway configuration
az network application-gateway show --name "azzzr-demo-appgw" --resource-group $resourceGroup --query "{zones:zones, sku:sku}"

# Check backend pool health
az network application-gateway show-backend-health --name "azzzr-demo-appgw" --resource-group $resourceGroup
```

### Part 3: Database High Availability
**Compare zone-redundant vs local redundancy:**

```powershell
# Show SQL Database configuration
az sql db show --server "azzzr-demo-sql" --name "azzzr-demo-sqldb" --resource-group $resourceGroup --query "{name:name, sku:currentSku, zoneRedundant:zoneRedundant}"

# Show backup storage redundancy
az sql db show --server "azzzr-demo-sql" --name "azzzr-demo-sqldb" --resource-group $resourceGroup --query "currentBackupStorageRedundancy"
```

### Part 4: Cache High Availability
**Demonstrate Redis clustering:**

```powershell
# Show Redis configuration
az redis show --name "azzzr-demo-redis" --resource-group $resourceGroup --query "{name:name, sku:sku, zones:zones, enableNonSslPort:enableNonSslPort}"
```

### Part 5: Failure Simulation
**Simulate zone failures to show failover:**

1. **VM Level Failover:**
```powershell
# Stop a VM in one zone to simulate zone failure
az vm deallocate --name "azzzr-demo-app-1" --resource-group $resourceGroup

# Show remaining healthy backends
az network application-gateway show-backend-health --name "azzzr-demo-appgw" --resource-group $resourceGroup
```

2. **Database Failover Testing:**
```powershell
# Initiate manual failover (if using failover groups)
# This would be configured for geo-replication scenarios
```

### Part 6: Performance Comparison
**Show latency differences:**

1. **Zonal Deployment Benefits:**
   - Lower latency (same zone communication)
   - Higher throughput for compute-intensive workloads
   - Cost optimization

2. **Zone-Redundant Benefits:**
   - Higher availability (99.99% vs 99.95% SLA)
   - Automatic failover capabilities
   - Business continuity assurance

### Part 7: Monitoring and Alerting
**Show availability monitoring:**

```powershell
# Query Log Analytics for availability metrics
az monitor log-analytics query --workspace "azzzr-demo-logs" --analytics-query "
Heartbeat
| where TimeGenerated > ago(1h)
| summarize LastHeartbeat = max(TimeGenerated) by Computer
| where LastHeartbeat < ago(5m)
"
```

### Demo Talking Points:

#### **Zonal Deployment (Optimized for Latency)**
- **Use Case:** Financial trading systems, real-time analytics
- **Benefits:** 
  - Ultra-low latency between components
  - Higher network throughput
  - Lower costs
- **Trade-offs:** 
  - Single point of failure (entire zone)
  - Manual disaster recovery required

#### **Zone-Redundant Deployment (Optimized for Availability)**
- **Use Case:** Critical business applications, customer-facing services
- **Benefits:**
  - Automatic failover across zones
  - Higher SLA guarantees
  - Built-in disaster recovery
- **Trade-offs:**
  - Higher latency due to cross-zone communication
  - Increased costs
  - More complex configuration

### Performance Metrics to Highlight:
1. **Latency:** Zonal: <1ms vs Zone-Redundant: 2-4ms
2. **Availability:** Zonal: 99.95% vs Zone-Redundant: 99.99%
3. **Cost:** Zonal: Baseline vs Zone-Redundant: +20-30%
4. **RTO/RPO:** Zonal: Manual (minutes/hours) vs Zone-Redundant: Automatic (seconds)
