function Add-TechIdAgentToGroup {
<#
.SYNOPSIS
    Adds one or more agents to an agent group.
.DESCRIPTION
    This command adds specified agents to an existing agent group. It first gets the group's current members,
    adds the new agent(s) to the list (avoiding duplicates), and then updates the group with the new member list.
    It fully supports -WhatIf for safe testing.
.PARAMETER AgentName
    The full, exact name of the agent to add to the group. This parameter supports pipeline input.
.PARAMETER DomainGuid
    The Domain GUID of the agent to add to the group.
.PARAMETER GroupName
    The name of the agent group to which the agent(s) will be added. This parameter is mandatory.
.PARAMETER Credential
    A PSCredential object. If omitted, the function will look for a saved credential file.
.PARAMETER ApiHost
    The base URL for the TechID API endpoint. Defaults to the configured default host.
.PARAMETER ShowApiCall
    If specified, the function will display the raw API request details before execution.
.EXAMPLE
    PS C:\> Add-TechIdAgentToGroup -AgentName "SERVER01\Admin" -GroupName "New Servers" -WhatIf

    Description:
    Shows that it would add the agent "SERVER01\Admin" to the "New Servers" group. No actual changes are made.
.EXAMPLE
    PS C:\> Get-TechIdAgents -AgentName "WEB-SRV-*" | Add-TechIdAgentToGroup -GroupName "Web Servers"

    Description:
    Finds all agents starting with "WEB-SRV-" and adds them to the "Web Servers" group.
.NOTES
    Author:      Daniel Houle
    Date:        2025-09-12
    Version:     3.0.0

    VERSION HISTORY:
    1.5.0 - 2025-10-07 - Added DomainGuid parameter set.
    1.4.0 - 2025-09-20 - Refactored to use the correct POST /client/agentgroup/{groupId}/agent/{agentId} endpoint per developer feedback.
#>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium', DefaultParameterSetName = 'ByName')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = 'Name', ParameterSetName = 'ByName')]
        [Alias('Name')]
        [string]$AgentName,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByGuid')]
        [string]$DomainGuid,

        [Parameter(Mandatory = $true)]
        [string]$GroupName,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(Mandatory = $false)]
        [string]$ApiHost,

        [Parameter(Mandatory = $false)]
        [switch]$ShowApiCall
    )

    begin {
        $Credential = Get-TechIdCredentialInternal -Credential $Credential
        if ([string]::IsNullOrWhiteSpace($ApiHost)) {
            $ApiHost = $script:DefaultApiHost
        }
    }

    process {
        try {
            # Step 1: Get the full details of the target group
            Write-Verbose "Retrieving details for group '$GroupName'..."
            $targetGroup = Get-TechIdAgentGroups -GroupName $GroupName -Credential $Credential -ApiHost $ApiHost -ShowApiCall:$false
            if (-not $targetGroup) {
                throw "Agent group '$GroupName' not found."
            }

            # Step 2: Get the agent object to be added
            $agentToAdd = $null
            if ($PSCmdlet.ParameterSetName -eq 'ByName') {
                $agentToAdd = Get-TechIdAgents -AgentName $AgentName -Credential $Credential -ApiHost $ApiHost -ShowApiCall:$false
                if (-not $agentToAdd) {
                    throw "Agent '$AgentName' not found."
                }
                if ($agentToAdd.Count -gt 1) {
                    throw "Multiple agents found matching '$AgentName'. Please provide a unique name or use -DomainGuid."
                }
            }
            else { # ByGuid
                $agentToAdd = Get-TechIdAgents -DomainGuid $DomainGuid -Credential $Credential -ApiHost $ApiHost -ShowApiCall:$false
                if (-not $agentToAdd) {
                    throw "Agent with DomainGuid '$DomainGuid' not found."
                }
            }

            # Step 3: Check if the agent is already a member
            $isAlreadyMember = $false
            if ($null -ne $targetGroup.Members) {
                $isAlreadyMember = $targetGroup.Members.Name -contains $agentToAdd.Name
            }

            if ($isAlreadyMember) {
                Write-Host "Agent '$($agentToAdd.Name)' is already a member of group '$GroupName'. No action needed." -ForegroundColor Yellow
                return
            }

            # Step 4: Prepare the API call using the correct endpoint
            $groupId = $targetGroup.DomainGroupId
            $agentId = $agentToAdd.DomainId
            
            if ($PSCmdlet.ShouldProcess("Group '$GroupName'", "Add agent '$($agentToAdd.Name)'")) {
                $apiRequest = @{
                    ApiHost         = $ApiHost
                    Credential      = $Credential
                    Endpoint        = "/client/agentgroup/$groupId/agent/$agentId"
                    Method          = 'POST'
                    ShowApiCall     = $ShowApiCall
                    CallingFunction = 'Add-TechIdAgentToGroup'
                }
                Invoke-TechIdApiRequest @apiRequest

                Write-Host "Successfully added agent '$($agentToAdd.Name)' to group '$GroupName'." -ForegroundColor Green
            }
        }
        catch {
            $errorMessage = $_.Exception.Message
            $identifyingParam = if ($PSCmdlet.ParameterSetName -eq 'ByName') { $AgentName } else { $DomainGuid }
            Write-Error "A fatal error occurred while trying to add agent '$identifyingParam' to group '$GroupName': $errorMessage"
        }
    }
}
