// Monitoring module for Zonal vs Zone-Redundant demo
// Deploys Azure Monitor + Log Analytics for observability

// Parameters
@description('Location for all resources')
param location string

@description('Resource name token')
param resourceToken string

@description('Tags to apply to all resources')
param tags object

// Variables
var logAnalyticsWorkspaceName = '${resourceToken}-law'
var applicationInsightsName = '${resourceToken}-ai'
// var dashboardName = '${resourceToken}-dashboard'  // Commented out while dashboard is disabled

// Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

// Dashboard temporarily commented out due to API compatibility issues
// Will be re-enabled after core infrastructure deployment
/*
// Dashboard to visualize performance and availability
resource dashboard 'Microsoft.Portal/dashboards@2020-09-01-preview' = {
  name: dashboardName
  location: location
  tags: tags
  properties: {
    lenses: [
      {
        order: 0
        parts: [
          {
            position: {
              x: 0
              y: 0
              colSpan: 6
              rowSpan: 4
            }
            metadata: {
              inputs: [
                {
                  name: 'resourceTypeMode'
                  isOptional: true
                  value: 'workspace'
                }
                {
                  name: 'ComponentId'
                  isOptional: true
                  value: {
                    SubscriptionId: subscription().subscriptionId
                    ResourceGroup: resourceGroup().name
                    Name: logAnalyticsWorkspace.name
                  }
                }
              ]
              type: 'Extension/AppInsightsExtension/PartType/AnalyticsGridTile'
              settings: {
                content: {
                  Query: 'Heartbeat | summarize by Computer, Category'
                  GridColumnsWidth: {
                    Computer: '200px'
                    Category: '200px'
                  }
                }
              }
              asset: {
                idInputName: 'ComponentId'
                type: 'ApplicationInsights'
              }
            }
          }
          {
            position: {
              x: 6
              y: 0
              colSpan: 6
              rowSpan: 4
            }
            metadata: {
              inputs: [
                {
                  name: 'resourceTypeMode'
                  isOptional: true
                  value: 'workspace'
                }
                {
                  name: 'ComponentId'
                  isOptional: true
                  value: {
                    SubscriptionId: subscription().subscriptionId
                    ResourceGroup: resourceGroup().name
                    Name: logAnalyticsWorkspace.name
                  }
                }
              ]
              type: 'Extension/AppInsightsExtension/PartType/AnalyticsLineChartTile'
              settings: {
                content: {
                  Query: 'Perf | where ObjectName == "Processor" and CounterName == "% Processor Time" | summarize AggregatedValue = avg(CounterValue) by Computer, bin(TimeGenerated, 15min)'
                }
              }
              asset: {
                idInputName: 'ComponentId'
                type: 'ApplicationInsights'
              }
            }
          }
          {
            position: {
              x: 0
              y: 4
              colSpan: 12
              rowSpan: 3
            }
            metadata: {
              inputs: [
                {
                  name: 'resourceTypeMode'
                  isOptional: true
                  value: 'workspace'
                }
                {
                  name: 'ComponentId'
                  isOptional: true
                  value: {
                    SubscriptionId: subscription().subscriptionId
                    ResourceGroup: resourceGroup().name
                    Name: logAnalyticsWorkspace.name
                  }
                }
              ]
              type: 'Extension/AppInsightsExtension/PartType/AnalyticsBarChartTile'
              settings: {
                content: {
                  Query: 'Perf | where ObjectName == "Memory" and CounterName == "Available MBytes" | summarize AggregatedValue = avg(CounterValue) by Computer'
                }
              }
              asset: {
                idInputName: 'ComponentId'
                type: 'ApplicationInsights'
              }
            }
          }
        ]
      }
    ]
    metadata: {
      model: {
        timeRange: {
          value: {
            relative: {
              duration: 24
              timeUnit: 1
            }
          }
          type: 'MsPortalFx.Composition.Configuration.ValueTypes.TimeRange'
        }
      }
    }
  }
}
*/

// Alert Rule to monitor latency
resource latencyAlertRule 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${resourceToken}-latency-alert'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert on high latency'
    severity: 2
    enabled: true
    scopes: [
      applicationInsights.id
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'High latency'
          metricName: 'requests/duration'
          operator: 'GreaterThan'
          threshold: 1000
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: []
  }
}

// Alert Rule to monitor availability
resource availabilityAlertRule 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${resourceToken}-availability-alert'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert on low availability'
    severity: 0
    enabled: true
    scopes: [
      applicationInsights.id
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'Low availability'
          metricName: 'availabilityResults/availabilityPercentage'
          operator: 'LessThan'
          threshold: 90
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: []
  }
}

// Outputs
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
output workspaceName string = logAnalyticsWorkspace.name
output applicationInsightsId string = applicationInsights.id
output applicationInsightsInstrumentationKey string = applicationInsights.properties.InstrumentationKey
