TechID Manager PowerShell Module - Quick Reference Guide
This guide provides a quick reference for all the commands available in the TechIdManager module.

Before You Begin: Obtaining an API Key
Before you can use this module, you will need a TechID API Key.

Note: To obtain an API Key, you must request one through your manager. API access is required to authenticate and use any of the commands in this module.

1. Initial Setup (Run Once)
This command securely stores your API credentials for all other commands to use.

Set-TechIdCredential

Purpose: Creates or updates the secure credential file and API endpoint configuration.

Note: All parameters (ManagerEmail, ApiKey, ApiHost) are mandatory.

Example:

Set-TechIdCredential -ManagerEmail "admin@example.com" -ApiKey "your-api-key-here" -ApiHost "https://api.techidmanager.com"

Optional Parameters:

-Path: Specifies a custom directory to save the credential file (Defaults to user home directory).

2. Technician Management
Commands for managing technician accounts and their settings.

Get-TechIdTech

Purpose: Retrieves one or more technician accounts.

Examples:

# Get all technicians
Get-TechIdTech

# Get technicians using a wildcard
Get-TechIdTech -Name "dant*"

Get-TechIdTechOption

Purpose: Retrieves the client option settings for a specific technician.

Examples:

# Get options for a specific technician
Get-TechIdTechOption -TechnicianName "dantest"

# Get options using the pipeline
Get-TechIdTech -Name "dantest" | Get-TechIdTechOption

Set-TechIdTechOption

Purpose: Modifies one or more client options for a specific technician.

Example:

# Safely test changing multiple options
Set-TechIdTechOption -Name "dantest" -MfaForTechIdClient "Force" -AllowExportKeys "No" -WhatIf

Add-TechIdTechToGroup

Purpose: Adds a technician to a technician group.

Examples:

# Add a technician to a group by name
Add-TechIdTechToGroup -TechnicianName 'dantest' -GroupName 'Level 2 Support'

# Safely test adding a technician using -WhatIf
Add-TechIdTechToGroup -TechnicianName 'dantest' -GroupName 'Level 2 Support' -WhatIf

# Add a technician using the pipeline
Get-TechIdTech -Name 'dantest' | Add-TechIdTechToGroup -GroupName 'Level 2 Support'

Remove-TechIdTechFromGroup

Purpose: Removes a technician from a technician group.

Examples:

# Remove a technician from a group
Remove-TechIdTechFromGroup -TechnicianName 'dantest' -GroupName 'Level 2 Support'

# Remove all members from a group using the pipeline
(Get-TechIdTechGroups -GroupName 'Project Alpha').Members | Remove-TechIdTechFromGroup -GroupName 'Project Alpha'

Get-TechIdTechMembership

Purpose: Finds which technician groups a specific technician belongs to.

Example:

# Find all groups a technician belongs to
Get-TechIdTechMembership -TechnicianName "dantest"

# Find memberships for multiple technicians efficiently using the pipeline and cache
Get-TechIdTech -Name "dant*" | Get-TechIdTechMembership

# Force a live API query, ignoring the cache
Get-TechIdTechMembership -TechnicianName "dantest" -NoCache

3. Agent (Domain) Management
Commands for managing agent records in the TechID portal.

Get-TechIdAgents

Purpose: Retrieves agent records.

Examples:

# Get all agents
Get-TechIdAgents

# Get specific agents using a wildcard
Get-TechIdAgents -AgentName "SERVER01*"

# Get an agent's current Account Leaf
Get-TechIdAgents -AgentName "DHOULEDEVTESTVM\VisorySU" | Select-Object Name, AccountLeaf

Set-TechIdAgentLeaf

Purpose: Assigns an agent to a specific account leaf, creating the leaf if it doesn't exist.

Example:

Get-TechIdAgents -AgentName "SERVER01*" | Set-TechIdAgentLeaf -Leaf "MyCompany.Customer.OldServers" -WhatIf

# Assign an agent using its GUID directly
Set-TechIdAgentLeaf -DomainGuid "36979b3e-295a-442d-9ced-c2ca06b0ff07" -Leaf "MyCompany.Customer.Site"

Remove-TechIdAgent

Purpose: Permanently deletes an agent record. This action cannot be undone.

Example:

# Safely test a bulk deletion with -Confirm to be prompted for each agent
Get-TechIdAgents -AgentName "OLD-SERVER-*" | Remove-TechIdAgent -Confirm

4. Group Management
Commands for managing agent and technician groups.

Get-TechIdAgentGroups

Purpose: Retrieves agent groups.

Examples:

# Get a summary of all agent groups
Get-TechIdAgentGroups

# Get full details for one group, including its members
Get-TechIdAgentGroups -GroupName "MSP-Domain-Shared"

Get-TechIdTechGroups

Purpose: Retrieves technician groups.

Example:

Get-TechIdTechGroups

Get-TechIdAgentMembership

Purpose: Finds which agent groups a specific agent belongs to.

Example:

# Find memberships for multiple agents efficiently using the pipeline and cache
Get-TechIdAgents -AgentName "DHOULEDEVTESTVM*" | Get-TechIdAgentMembership

# Force a live API query, ignoring the cache
Get-TechIdAgentMembership -AgentName "DHOULEDEVTESTVM\VisorySU" -NoCache

Add-TechIdAgentToGroup

Purpose: Adds one or more agents to an agent group.

Example:

Get-TechIdAgents -AgentName "WEB-SRV-*" | Add-TechIdAgentToGroup -GroupName "Web Servers" -WhatIf

Remove-TechIdAgentFromGroup

Purpose: Removes one or more agents from an agent group.

Example:

Get-TechIdAgents -AgentName "WEB-SRV-*" | Remove-TechIdAgentFromGroup -GroupName "Web Servers" -WhatIf

Remove-TechIdTechGroup

Purpose: Deletes a technician group.

Example:

Remove-TechIdTechGroup -GroupName "Old Support Tier" -WhatIf

Remove-TechIdAgentGroup

Purpose: Deletes an agent group.

Example:

Remove-TechIdAgentGroup -GroupName "Decommissioned Servers" -WhatIf

5. Account Leaf Management
Commands for managing the organizational hierarchy (leafs).

Get-TechIdLeaf

Purpose: Retrieves all account leafs.

Examples:

# Get all leafs
Get-TechIdLeaf

# Get specific leaf by path
Get-TechIdLeaf -Path "MyCompany.Customer.NewSite"

# Get leafs using wildcard
Get-TechIdLeaf -Path "MyCompany.Customer.*"

New-TechIdLeaf

Purpose: Creates a new account leaf.

Example:

New-TechIdLeaf -Path "MyCompany.Customer.NewSite" -WhatIf

Remove-TechIdLeaf

Purpose: Removes an account leaf.

Examples:

# Remove by ID
Remove-TechIdLeaf -Id 123 -WhatIf

# Remove by Path (Name)
Remove-TechIdLeaf -Path "MyCompany.Customer.OldSite" -WhatIf

6. Account Management
Commands for managing the account itself.

Get-TechIdAPIKeys

Purpose: Retrieves the API keys for the current account.

Example:

Get-TechIdAPIKeys

---

## Common Questions & "Gotchas"

### How do I get the Account Leaf for a specific agent?

The `Get-TechIdAgents` command returns a full agent object, which includes the `AccountLeaf` property. You do not need to pipe to another command.

**Correct Usage:**
```powershell
# To get the full agent object, including the AccountLeaf property
Get-TechIdAgents -AgentName 'DHOULEDEVTESTVM\MSP-Local-JIT'

# To get ONLY the value of the AccountLeaf property
(Get-TechIdAgents -AgentName 'DHOULEDEVTESTVM\MSP-Local-JIT').AccountLeaf
```

### Why doesn't `Get-TechIdAgents | Get-TechIdLeaf` work?

The `Get-TechIdLeaf` function is designed to get **all** leafs from the API (or filter by name). It does not accept input from the pipeline to filter the results based on an agent object. When you use that pipeline, the agent object is ignored, and `Get-TechIdLeaf` simply returns its default output.