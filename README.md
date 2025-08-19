# Repository Reorganization Guide

## Purpose
This document maps the reorganization of a PowerShell/Azure automation repository from a flat/mixed structure to a logical, category-based folder structure. The goal is to make scripts easily discoverable for junior engineers and team members.

## Context
- **Original State**: ~120 PowerShell scripts mixed across various folders without clear organization
- **Target State**: Scripts organized by service/platform (Azure services, Active Directory, AWS, etc.)
- **Approach**: Create new repo structure, copy files to preserve original, no code changes

## Instructions for Implementation
1. Create a new repository folder (e.g., "Azure-Organized")
2. Create all folder structures listed below
3. Copy files from source locations to target folders as mapped
4. Verify all files copied successfully
5. Update any hardcoded paths if needed
6. Replace old repo or push new structure to GitHub

## Key Decisions Made
- **Grouping Logic**: Files grouped by service/platform rather than by script type
- **Azure Focus**: Most scripts are Azure-related, so Azure gets detailed subfolders
- **Functions Separate**: Reusable functions kept in dedicated folder for module development
- **No Code Changes**: This is organization only - all scripts remain unchanged
- **Flat Where Appropriate**: Some categories kept simple (e.g., AWS, GitHub) as they have fewer scripts

## File Reorganization Mapping

### Azure/VMs/
* `get-all-azure-vm-info.ps1`
* `get-azure-vm-activity-logs.ps1`
* `run-command-on-azure-vm.ps1`
* `run-script-on-all-az-vms.ps1` (from powershell/)
* `checkrunningservices-onazurevm.ps1`
* `get-all-vm-tags.ps1`
* `get-windows-vm-users-for-all-azure-vms.ps1` (from azure-vms/)
* `change-2nd-dns-ip.ps1`
* `deploy-node0VM.ps1`
* `get-vm-users.ps1` (from azure-vms/)

### Azure/Networking/
* `new-network-and-peer-to-spoke.ps1`
* `azure-network-setup.sh` (from az-bash-cli/)

### Azure/Storage/
* `disable-public-access-for-azstorage-account.ps1`
* `create-download-link.ps1`

### Azure/Databases/
* `get-azure-db-info-for-all-subs.ps1`
* `get-az-sql-db-activity.ps1`
* `Get-AzureSQLDatabasesAndCreateADGroups.ps1`
* `GetSQLBackups.ps1`

### Azure/Costs/
* `get-azure-cost-for-subscription.ps1`
* `azure-costs-for-previous-month.ps1`
* `azure-costs-for-vm-for-past-month.ps1` (from costs/)
* `get-costs-for-all-vms-in-all-subscriptions.ps1` (from costs/)
* `AzureCostReport.ps1` (from costs/)
* `Get-AzureCostInfo.ps1`

### Azure/Backups/
* `azvm-backup.ps1` (from backups/)
* `check-azvmbackupstatus.ps1` (from backups/)
* `get-azvmbackups.ps1` (from powershell/)

### Azure/KeyVault/
* `get-all-keyvault-secrets.ps1`
* `create-bitlocker-lab.ps1`

### Azure/Arc/
* `delete-expired-arc-agents.ps1`
* `get-arc-servers`
* `run-arccmd.ps1` (from arc/)

### Azure/Tags/
* `tag-azresources.ps1`
* `tag-existing-vms.ps1` (from tags/)
* `get-aztags.ps1`

### Azure/Policies/
* `tag-all-resources-in-sub.json` (from policies/)
* `Enable-PurgeProtectionForAllKeyVaults.ps1` (from policy-remediations/)

### Azure/ResourceGraphQueries/
* `all storage accounts with public network access enabled` (from Azure Resource Graph Explorer/)
* `Combined Azure VMs and Arc Machines Inventory` (from Azure Resource Graph Explorer/)
* `Find VMs with no NSG or NSGs open to internet` (from Azure Resource Graph Explorer/)
* `Get VMs with public IPs and their NSG rules` (from Azure Resource Graph Explorer/)
* `log-analytics-workspace.queries.sh` (from Azure Resource Graph Explorer/)

### Azure/WebApps/
* `get-az-webapp-activity.ps1`

### Azure/Monitoring/
* `enable-alerts.ps1`
* `list-all-azure-and-arc-vms.json` (from workbook_templates/)

### Azure/ACR/
* `list-old-acr-images.ps1`

### Azure/Users/
* `list-all-users-last-login-date.ps1`
* `get-e1-licenses.ps1`

### Azure/Groups/
* `new-azgroup.ps1`

### Azure/Installation/
* `install-screenconnect.ps1`
* `install-carbonblack.ps1`
* `deploy-arc-and-sqlncli.ps1`

### SharePoint/
* `Track-SalesEmailsToSharePoint.ps1` (from Track-SalesEmailsToSharePoint/)
* `README.md` (from Track-SalesEmailsToSharePoint/)
* `extract-info-from-sp-url.ps1` (from sharepoint/)
* `search-your-sharepoint.ps1` (from sharepoint/)

### ActiveDirectory/
* `offboard-multi-domain-user.ps1` (from powershell/)
* `checkfornewADUsers.ps1` (from powershell/)
* `activedirectory-perms.ps1` (from powershell/)
* `get-ad-user-info.ps1` (from powershell/)
* `get-primary-dc.ps1` (from powershell/)
* `list-domain-controllers.ps1` (from powershell/)

### AWS/
* `New-AWSWorkspaceNotification.ps1` (from powershell/)
* `workspace-commands.ps1` (from AWS/)

### VMware-ESXi/
* `shutdown-esxi.ps1` (from esxi/)
* `install-esxi-on-server.ps1` (from esxi/)
* `install-zabbix-on-all-esxi-win-vms.ps1`
* `NEWinstall-zabbix-on-all-esxi-win-vms.ps1`
* `run-command-on-all-vms.ps1` (from powershell/)
* `dns-ip-win-vms.ps1` (from powershell/)

### Windows/
* `install-and-run-winget.ps1` (from Windows/)
* `show-logged-users.ps1` (from Windows/)
* `ConfigureRemotingForAnsible.ps1`
* `Install-Zabbix.ps1`

### PowerShell-Utils/
* `get-drivespace.ps1` (from powershell/)
* `get-vmdriveamount.ps1` (from powershell/)
* `Compare-FileHashes.ps1` (from powershell/)
* `reset-local-password.ps1` (from powershell/)
* `install-smms.ps1` (from powershell/)
* `install-software-when-hostname-resolves.ps1` (from powershell/)
* `send-email.ps1` (from powershell/)
* `get-old-files.ps1`
* `enable-psremoting.ps1`
* `uninstall-kaseya.ps1` (from powershell/)

### Functions/
* `SendAzureEmail.ps1` (from functions/)
* `GetAzureToken.ps1` (from functions/)
* `GetAzureSubscriptionCosts.ps1` (from functions/)

### Terraform/
* `terraform-azure-vm-for-ansibleAAP.tf`
* `terraformer.ps1` (from terraformer/)
* `supported-azure-objects.txt` (from terraformer/)

### Ansible/
* `get-ansible-settings.ps1`
* `set-win11-vm-ansible.ps1` (from ansible/)
* `set-winserver-ansible.ps1` (from ansible/)

### GitHub/
* `get-github-repos-and-delete.ps1`
* `create-githubrepo.ps1`
* `github-repo-migrator.ps1` (from github/)

### Atlassian/
* Keep `Untitled.txt` file as is (appears to be Confluence tools documentation)

### Monitoring/Zabbix/
* `Install-Zabbix.ps1`
* `install-zabbix-on-all-esxi-win-vms.ps1`
* `NEWinstall-zabbix-on-all-esxi-win-vms.ps1`

### Monitoring/Lansweeper/
* `get-allDevices.ps1` (from lansweeper/)

### Graph-API/
* `Add-UserandManager.ps1` (from Graph/)
* `connect-microsoft-graph.ps1`
* `Get-MFAUsers.ps1`
* `SendEmailGraphAPI.ps1`

### Examples/
* `demo-env.sh` (from az-bash-cli/)
* `youni-dev.sh` (from az-bash-cli/)
* `AZ-Auth.ps1`
* `create-dummy-resources-in-azure.ps1`
* `Get-AzureVMInventory.ps1`
* `user_permissions.ps1`

### Projects/
* `get-users-email.ps1` (from projects/track-users-emails/)
* `meraki.ps1`
* `ssh-copy-windows.ps1`
* `test.sh`
* `resources.xml`
* `TrackEmailData.ps1`

### Root (Keep in root for now)
* `README.md`
* `Untitled.txt`
* `Install Az-cli,azure ansible dependencies for RHEL.sh`
* `install-remote-server.ps1`
* `run-script-on-all-win-azure-vms.ps1`
* `AzureKeyvaultAccesstoAppServices`

## Notes
- Files with (from folder/) indicate their current location
- Files without notes are already in Azure/ root or project root
- Some files may need review for proper categorization

## For LLM/AI Assistant Context
If you're an AI assistant working with this reorganization:
1. **Preserve Originals**: Always work on a copy, never modify the source repository directly
2. **Validation**: After reorganization, validate that file count matches (should be ~120 files)
3. **Path Updates**: Check scripts for hardcoded paths that may need updating
4. **Git History**: If using git, consider using `git mv` to preserve file history
5. **Dependencies**: Some scripts may reference others - maintain these relationships
6. **Testing Priority**: Test critical automation scripts first (backup, cost management, VM management)

## Success Criteria
- [ ] All files accounted for and moved to logical locations
- [ ] Folder structure is intuitive for junior engineers
- [ ] No scripts were modified (only moved)
- [ ] Original repository remains intact as backup
- [ ] README updated with new structure navigation
