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


resources
| where type == "microsoft.compute/virtualmachines" or type == "microsoft.hybridcompute/machines"
| project VMName = name, VMId = id, Subscription = subscriptionId

