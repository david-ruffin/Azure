// First, let's see what metrics each VM is sending
VMComputer
| where TimeGenerated > ago(1h)
| distinct Computer
| join kind=leftouter (
    InsightsMetrics
    | where TimeGenerated > ago(1h)
    | summarize 
        HasCPUMetrics = countif(Namespace == 'Processor' and Name == 'UtilizationPercentage'),
        HasDiskMetrics = countif(Namespace == 'LogicalDisk'),
        HasNetworkMetrics = countif(Namespace == 'Network')
    by Computer
) on Computer
| project 
    Computer,
    HasCPUMetrics = iif(HasCPUMetrics > 0, true, false),
    HasDiskMetrics = iif(HasDiskMetrics > 0, true, false),
    HasNetworkMetrics = iif(HasNetworkMetrics > 0, true, false)
| sort by HasCPUMetrics asc, Computer asc

// Start with all VMs from VMComputer
VMComputer
| where TimeGenerated > ago(1h)
| extend AzureResourceId = _ResourceId
| extend VMType = iff(isempty(AzureResourceId) or AzureResourceId startswith "/subscriptions/", "Azure VM", "Azure Arc")
| distinct Computer, VMType, _ResourceId
| join kind=leftouter (
    InsightsMetrics
    | where TimeGenerated > ago(1h)
    | where Namespace == "Processor" and Name == "UtilizationPercentage"
    | summarize CPUAvg = avg(Val) by Computer
) on Computer
| project Computer, VMType, _ResourceId, CPUAvg, HasCPUMetrics = isnotnull(CPUAvg)


InsightsMetrics
| where TimeGenerated > ago(1h)
| where Namespace == "Processor" and Name == "UtilizationPercentage" 
| summarize LastHeartbeat = max(TimeGenerated) by Computer
| project Computer, LastHeartbeat
| order by LastHeartbeat desc

VMComputer
| where TimeGenerated > ago(1h)
| distinct Computer, _ResourceId


// Simplified version without let statements
VMComputer
| where TimeGenerated > ago(24h)
| distinct Computer, _ResourceId
| join kind=leftouter (
    Heartbeat
    | where TimeGenerated > ago(24h)
    | summarize LastHeartbeat = max(TimeGenerated) by Computer
) on Computer
| join kind=leftouter (
    InsightsMetrics
    | where TimeGenerated > ago(24h)
    | where Namespace in ("Processor", "LogicalDisk", "Network")
    | summarize LastMetric = max(TimeGenerated) by Computer
) on Computer
| project 
    Computer,
    ['Is Discovered in VMComputer'] = "Yes",
    ['Last Heartbeat'] = LastHeartbeat,
    ['Last Metric'] = LastMetric,
    ['Heartbeat-to-Metric Lag'] = case(
        isnotempty(LastHeartbeat) and isnotempty(LastMetric), tostring(LastHeartbeat - LastMetric),
        isnotempty(LastHeartbeat), "No Metrics",
        "Agent Offline"
    ),
    ['Status'] = case(
        isnotempty(LastMetric), "Data Flowing",
        isnotempty(LastHeartbeat), "Agent Connected (No Metrics)",
        "Agent Offline/Not Reporting"
    )
| sort by ['Status'] asc

