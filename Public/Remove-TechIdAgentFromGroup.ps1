function Remove-TechIdAgentFromGroup {
<#
.SYNOPSIS
    Removes one or more agents from an agent group.
.DESCRIPTION
    This command removes specified agents from an existing agent group.
    It fully supports -WhatIf for safe testing.
.PARAMETER AgentName
    The full, exact name of the agent to remove from the group. This parameter supports pipeline input.
.PARAMETER DomainGuid
    The Domain GUID of the agent to remove from the group.
.PARAMETER GroupName
    The name of the agent group from which the agent(s) will be removed. This parameter is mandatory.
.PARAMETER Credential
    A PSCredential object. If omitted, the function will look for a saved credential file.
.PARAMETER ApiHost
    The base URL for the TechID API endpoint. Defaults to 'https://ch010.ruffiansoftware.com'.
.EXAMPLE
    PS C:\> Remove-TechIdAgentFromGroup -AgentName "SERVER01\Admin" -GroupName "Old Servers" -WhatIf

    Description:
    Shows that it would remove the agent "SERVER01\Admin" from the "Old Servers" group. No actual changes are made.
.EXAMPLE
    PS C:\> (Get-TechIdAgentGroups -GroupName "Decommissioned").Members | Remove-TechIdAgentFromGroup -GroupName "Decommissioned"

    Description:
    Finds all members of the "Decommissioned" group and then removes them from that same group.
.NOTES
    Author:      Daniel Houle
    Date:        2025-09-19
    Version:     1.4.0

    VERSION HISTORY:
    1.4.0 - 2025-10-07 - Added DomainGuid parameter set.
    1.3.0 - 2025-09-20 - Refactored to use the correct DELETE /client/agentgroup/{groupId}/agent/{agentId} endpoint per developer feedback.
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
        [string]$ApiHost = "https://ch010.ruffiansoftware.com",

        [Parameter(Mandatory = $false)]
        [switch]$ShowApiCall
    )

    begin {
        $Credential = Get-TechIdCredentialInternal -Credential $Credential
    }

    process {
        try {
            # Step 1: Get the full details of the target group
            Write-Verbose "Retrieving details for group '$GroupName'..."
            $targetGroup = Get-TechIdAgentGroups -GroupName $GroupName -Credential $Credential -ApiHost $ApiHost -ShowApiCall:$false
            if (-not $targetGroup) {
                throw "Agent group '$GroupName' not found."
            }

            # Step 2: Find the agent to remove from the group's member list
            $agentToRemove = $null
            if ($PSCmdlet.ParameterSetName -eq 'ByName') {
                $agentsInGroup = $targetGroup.Members | Where-Object { $_.Name -eq $AgentName }
                if ($agentsInGroup.Count -gt 1) {
                    throw "Multiple agents named '$AgentName' found in group '$GroupName'. Please use -DomainGuid to specify which agent to remove."
                }
                $agentToRemove = $agentsInGroup
            }
            else { # ByGuid
                $agentToRemove = $targetGroup.Members | Where-Object { $_.DomainGuid -eq $DomainGuid }
            }

            if (-not $agentToRemove) {
                $identifier = if ($PSCmdlet.ParameterSetName -eq 'ByName') { $AgentName } else { "with GUID $DomainGuid" }
                Write-Host "Agent '$identifier' is not a member of group '$GroupName'. No action needed." -ForegroundColor Yellow
                return
            }

            # Step 3: Prepare the API call using the correct endpoint
            $groupId = $targetGroup.DomainGroupId
            $agentId = $agentToRemove.DomainId
            $resolvedAgentName = $agentToRemove.Name
            
            if ($PSCmdlet.ShouldProcess("Group '$GroupName'", "Remove agent '$resolvedAgentName'")) {
                $apiRequest = @{
                    ApiHost         = $ApiHost
                    Credential      = $Credential
                    Endpoint        = "/client/agentgroup/$groupId/agent/$agentId"
                    Method          = 'DELETE'
                    ShowApiCall     = $ShowApiCall
                    CallingFunction = 'Remove-TechIdAgentFromGroup'
                }
                Invoke-TechIdApiRequest @apiRequest

                Write-Host "Successfully removed agent '$resolvedAgentName' from group '$GroupName'." -ForegroundColor Green
            }
        }
        catch {
            $errorMessage = $_.Exception.Message
            $identifyingParam = if ($PSCmdlet.ParameterSetName -eq 'ByName') { $AgentName } else { $DomainGuid }
            Write-Error "A fatal error occurred while trying to remove agent '$identifyingParam' from group '$GroupName': $errorMessage"
        }
    }
}
