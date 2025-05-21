#Requires -Version 7.0
#Requires -Modules Az

<#
.SYNOPSIS
    Deployment script for Zonal vs. Zone-Redundant architecture demo in Azure.
.DESCRIPTION
    This script deploys the infrastructure components for demonstrating the tradeoffs
    between zonal deployments (optimized for low latency) and zone-redundant deployments
    (optimized for high availability).
.PARAMETER ResourceGroupName
    Name of the resource group to deploy resources into.
.PARAMETER Location
    Azure region to deploy resources to (default: South Africa North).
.PARAMETER DeploymentName
    Name for the deployment (default: "zonal-zone-redundant-demo").
.PARAMETER IsZoneRedundant
    Switch to deploy in zone-redundant configuration. If not specified, deploys in zonal configuration.
.PARAMETER AdminUsername
    Admin username for VMs and databases.
.PARAMETER AdminPassword
    Admin password for VMs and databases.
#>

param (
    [Parameter(Mandatory = $true)]
    [string] $ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [string] $Location = "southafricanorth",

    [Parameter(Mandatory = $false)]
    [string] $DeploymentName = "zonal-zone-redundant-demo",

    [Parameter(Mandatory = $false)]
    [switch] $IsZoneRedundant,

    [Parameter(Mandatory = $true)]
    [string] $AdminUsername,

    [Parameter(Mandatory = $true)]
    [securestring] $AdminPassword
)

# Ensure connected to Azure
try {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Not connected to Azure. Please run Connect-AzAccount first."
        exit
    }
    
    Write-Host "Connected to subscription: $($context.Subscription.Name) ($($context.Subscription.Id))" -ForegroundColor Green
}
catch {
    Write-Host "Error checking Azure connection. Please run Connect-AzAccount first." -ForegroundColor Red
    exit
}

# Create or ensure resource group exists
try {
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-Host "Creating resource group $ResourceGroupName in $Location..." -ForegroundColor Yellow
        $rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location
        Write-Host "Resource group created." -ForegroundColor Green
    }
    else {
        Write-Host "Resource group $ResourceGroupName already exists." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Error creating resource group: $_" -ForegroundColor Red
    exit
}

# Deploy using Bicep template
try {
    $deploymentConfig = @{
        Name                  = $DeploymentName
        ResourceGroupName     = $ResourceGroupName
        TemplateFile          = "./infra/main.bicep"
        isZoneRedundant       = $IsZoneRedundant.IsPresent
        adminUsername         = $AdminUsername
        adminPassword         = $AdminPassword
        Verbose               = $true
        ErrorAction           = "Stop"
    }

    Write-Host "Starting deployment..." -ForegroundColor Yellow
    Write-Host "Deployment mode: $(if ($IsZoneRedundant) { 'Zone-Redundant (High Availability)' } else { 'Zonal (Low Latency)' })" -ForegroundColor Yellow
    
    # What-if first to preview changes
    Write-Host "Previewing deployment changes..." -ForegroundColor Yellow
    $whatIfResult = New-AzResourceGroupDeployment @deploymentConfig -WhatIf
    
    # Prompt for confirmation
    $confirmation = Read-Host "Do you want to proceed with this deployment? (y/n)"
    if ($confirmation -ne 'y') {
        Write-Host "Deployment cancelled." -ForegroundColor Red
        exit
    }
    
    # Execute the deployment
    $deployment = New-AzResourceGroupDeployment @deploymentConfig
    
    Write-Host "Deployment completed successfully!" -ForegroundColor Green
    
    # Output relevant information
    Write-Host "`nDeployment Outputs:" -ForegroundColor Cyan
    Write-Host "Deployment Type: $($deployment.Outputs.deploymentType.Value)" -ForegroundColor Green
    Write-Host "`nEndpoints:" -ForegroundColor Yellow
    Write-Host "Front Door Endpoint: https://$($deployment.Outputs.frontDoorEndpoint.Value)" -ForegroundColor White
    Write-Host "Application Gateway Public IP: $($deployment.Outputs.appGatewayPublicIp.Value)" -ForegroundColor White
    Write-Host "API Management Endpoint: $($deployment.Outputs.apiManagementEndpoint.Value)" -ForegroundColor White
    Write-Host "Redis Cache Hostname: $($deployment.Outputs.redisCacheHostName.Value)" -ForegroundColor White
    Write-Host "SQL Server FQDN: $($deployment.Outputs.sqlServerFqdn.Value)" -ForegroundColor White
    
    # Generate info about monitoring resources
    Write-Host "`nMonitoring:" -ForegroundColor Yellow
    Write-Host "Log Analytics Workspace: $($deployment.Outputs.monitoringWorkspaceName.Value)" -ForegroundColor White
    
    # Validate deployment
    Write-Host "`nValidating deployment..." -ForegroundColor Cyan
    
    # Check if Front Door is accessible
    try {
        $frontDoorUrl = "https://$($deployment.Outputs.frontDoorEndpoint.Value)"
        Write-Host "Testing connection to Front Door: $frontDoorUrl" -ForegroundColor Yellow
        $frontDoorResponse = Invoke-WebRequest -Uri $frontDoorUrl -TimeoutSec 60 -Method Head -ErrorAction SilentlyContinue
        
        if ($frontDoorResponse.StatusCode -eq 200) {
            Write-Host "✓ Front Door is responding properly." -ForegroundColor Green
        } else {
            Write-Host "⚠ Front Door returned status code: $($frontDoorResponse.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠ Could not connect to Front Door. This is expected if backend services are still starting up." -ForegroundColor Yellow
    }
    
    # Deployment summary
    Write-Host "`nDeployment Summary:" -ForegroundColor Cyan
    Write-Host "- Resource Group: $ResourceGroupName" -ForegroundColor White
    Write-Host "- Location: $Location" -ForegroundColor White
    Write-Host "- Configuration: $($deployment.Outputs.deploymentType.Value)" -ForegroundColor White
    
    # Next steps
    Write-Host "`nNext Steps:" -ForegroundColor Green
    Write-Host "1. Wait 10-15 minutes for all services to fully provision and configure." -ForegroundColor White
    Write-Host "2. Access the Front Door endpoint to test the deployment." -ForegroundColor White
    Write-Host "3. Run performance tests to compare latency and availability metrics." -ForegroundColor White
    
    # Clean up reminder
    Write-Host "`nReminder: When finished testing, clean up resources by running:" -ForegroundColor Yellow
    Write-Host "Remove-AzResourceGroup -Name `"$ResourceGroupName`" -Force" -ForegroundColor White
}
catch {
    Write-Host "Error during deployment: $_" -ForegroundColor Red
    Write-Host $_.Exception.Message
    Write-Host $_.ScriptStackTrace
    exit
}
