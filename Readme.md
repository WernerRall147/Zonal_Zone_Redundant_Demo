📄 Statement of Work (SOW)
1. Objective
Design and implement a scaled-down demo of a zonal vs. zone-redundant deployment for a Nice Actimize-like application in Azure. The goal is to showcase architectural trade-offs between performance (low latency) and resilience (high availability).

2. Scope
Deploy core components across multiple Availability Zones (AZs) in a single Azure region.
Use Azure-native services (no Cloudflare).
Automate deployment using ARM templates.
Demonstrate failover, latency, and resilience behavior.
3. Architecture Overview
Azure Front Door for global routing.
Azure Application Gateway (WAF) for web protection.
API Management for API traffic control.
App Servers & ESB deployed across AZs.
Oracle DB with Data Guard (or simulated with SQL for demo).
Azure Cache for Redis with geo-replication.
Proximity Placement Groups (PPGs) for intra-AZ latency optimization.
Accelerated Networking for VM performance.
4. Assumptions
Single-region deployment (e.g., South Africa North).
Demo will simulate production behavior but at reduced scale.
GitHub Copilot will assist with ARM template authoring.
5. Deliverables
Architecture diagram and documentation.
ARM templates and GitHub repo.
Deployment guide and validation checklist.
Live demo environment.
Presentation deck for stakeholders.
6. Timeline
Week	Milestone
1	Architecture design + GitHub repo setup
2	ARM template development
3	Deployment + testing
4	Demo walkthrough + documentation
5	Final presentation
🛠 Deployment Implementation Document
1. Prerequisites
Azure subscription with quota for VMs, networking, and storage.
Access to Azure CLI, PowerShell, and GitHub.
GitHub Actions enabled for CI/CD.
2. Azure Services Used
Component	Azure Service
Global Routing	Azure Front Door
Web Firewall	Azure Application Gateway (WAF)
API Gateway	Azure API Management
App Layer	Azure VMs with Accelerated Networking
Database	Oracle DB (or SQL for demo) with Data Guard
Caching	Azure Cache for Redis
Latency Optimization	Proximity Placement Groups
Monitoring	Azure Monitor + Log Analytics
3. Deployment Steps
Networking

Create VNets, subnets, NSGs, and route tables.
Enable Accelerated Networking.
PPGs

Create one PPG per AZ.
Assign VMs to PPGs during deployment.
Compute

Deploy App and ESB VMs across AZs using ARM templates.
Database

Deploy Oracle DB or SQL with replication (simulate Data Guard).
Caching

Deploy Redis with geo-replication enabled.
Traffic Management

Deploy Azure Front Door and Application Gateway.
Configure routing rules and health probes.
Monitoring

Enable Azure Monitor and Log Analytics.
Set up alerts for latency, availability, and failover.
4. ARM Template Requirements
Modular templates for:
Networking
Compute (VMs + PPGs)
Database
Caching
Traffic management
Parameters for AZ selection, VM size, and region.
Outputs for IPs, DNS, and health status.
5. GitHub Copilot Integration
Store templates in a structured GitHub repo.
Use GitHub Actions for deployment automation.
Leverage Copilot to:
Generate ARM syntax
Validate template structure
Suggest improvements