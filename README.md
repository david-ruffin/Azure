# Azure PowerShell Automation Repository

## Overview
Collection of 120+ PowerShell scripts for Azure, Active Directory, and infrastructure automation built over several years of enterprise administration.

## Contents

### Azure Automation
- **VM Management**: Deployment, monitoring, backup, user auditing
- **Cost Management**: Subscription costs, VM costs, monthly reports
- **Networking**: VNet peering, NSG management, network setup
- **Storage**: Public access controls, file management
- **Databases**: SQL Server management, backup verification
- **Security**: KeyVault secrets, RBAC, tags, policies
- **Arc**: Hybrid server management
- **Monitoring**: Log Analytics queries, alerts, workbooks

### Infrastructure Tools
- **Active Directory**: User management, permissions, domain controllers
- **VMware/ESXi**: VM automation, shutdown procedures
- **Windows Administration**: Software deployment, remote management
- **SharePoint**: Document management, email tracking
- **AWS**: Workspace automation

### Integrations
- **Microsoft Graph API**: User/group management, email automation
- **GitHub**: Repository management, migration tools
- **Atlassian**: Confluence/Jira automation (see documentation)
- **Monitoring**: Zabbix, Lansweeper deployment

## Requirements
- PowerShell 5.1 or later
- Azure PowerShell modules (`Az.*`)
- Microsoft Graph PowerShell SDK (for Graph API scripts)
- Appropriate Azure RBAC permissions
- Service Principal for automation (where applicable)

## Usage
Scripts are currently organized by source/category. Each script includes:
- Synopsis in header comments
- Required parameters
- Prerequisites noted in comments

Example:
```powershell
# For VM information across subscriptions
.\Azure\get-all-azure-vm-info.ps1

# For cost reporting
.\Azure\costs\AzureCostReport.ps1
```

## Authentication
Most scripts support multiple authentication methods:
- Interactive: `Connect-AzAccount`
- Service Principal: Using client ID/secret
- Managed Identity: For Azure-hosted automation

## Important Scripts

### Daily Operations
- `get-all-azure-vm-info.ps1` - Complete VM inventory
- `check-azvmbackupstatus.ps1` - Backup verification
- `AzureCostReport.ps1` - Monthly cost emails

### Emergency Procedures
- `shutdown-esxi.ps1` - ESXi graceful shutdown
- `azvm-backup.ps1` - On-demand VM backup
- `enable-alerts.ps1` - Alert management

### Automation
- `tag-azresources.ps1` - Auto-tagging resources
- `Track-SalesEmailsToSharePoint.ps1` - Email tracking automation

## Repository Reorganization
See `reorg.md` for planned structure improvements to make scripts more discoverable.

## Notes
- Scripts maintain error handling and logging
- Sensitive data (keys, passwords) should use KeyVault or environment variables
- Test in non-production before running against production resources

## Contributing
- Maintain consistent parameter naming
- Include synopsis and examples in script headers
- Test scripts before committing
- Update this README when adding new categories

## Support
Internal repository - refer questions to IT/DevOps team

---
*Repository contains production scripts - use with appropriate caution*
