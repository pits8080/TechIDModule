function Remove-TechIdAgent {
<#
.SYNOPSIS
    Deletes an agent record from the TechID portal.
.DESCRIPTION
    This command permanently deletes a registered agent record (domain) from TechID.
    For safety, this command requires an exact name match and does not support wildcards.
    It fully supports the -WhatIf and -Confirm parameters.
.PARAMETER AgentName
    The full, exact name of the agent to be deleted (e.g., "DHOULEDEVTESTVM\VisorySU"). This parameter is mandatory.
.PARAMETER DomainGuid
    The unique Domain GUID of the agent to be deleted.
.PARAMETER Credential
    A PSCredential object. If omitted, the function will look for a saved credential file.
.PARAMETER ApiHost
    The base URL for the TechID API endpoint. Defaults to 'https://ch010.ruffiansoftware.com'.
.PARAMETER ShowApiCall
    If specified, the function will display the raw API request details before execution.
.EXAMPLE
    PS C:\> Remove-TechIdAgent -AgentName "OLDSERVER\Agent" -WhatIf

    Description:
    Shows that it would delete the agent record for "OLDSERVER\Agent" without actually performing the deletion.
.EXAMPLE
    PS C:\> Get-TechIdAgents -AgentName "OLDSERVER*" | Remove-TechIdAgent -Confirm

    Description:
    Finds all agents starting with "OLDSERVER" and, for each one, prompts for confirmation before deleting it.
.EXAMPLE
    PS C:\> Remove-TechIdAgent -DomainGuid "83f362b6-2e4b-4b37-bcd1-23162f621b3e"

    Description:
    Deletes the agent record with the specified Domain GUID, with a confirmation prompt.
.NOTES
    Author:      Daniel Houle
    Date:        2025-09-11
    Version:     2.4.0

    VERSION HISTORY:
    2.4.0 - 2025-10-23 - Added DomainGuid parameter set for deletion by GUID.
    2.3.0 - 2025-09-15 - Corrected endpoint to use singular /domain per developer feedback.
#>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High', DefaultParameterSetName = 'ByName')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ByName')]
        [Alias('Name')]
        [string]$AgentName,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ByGuid')]
        [string]$DomainGuid,

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
            $agentToDelete = $null
            $identifyingParam = $null

            if ($PSCmdlet.ParameterSetName -eq 'ByName') {
                $identifyingParam = $AgentName
                Write-Verbose "Searching for agent record '$AgentName'..."
                $agentToDelete = Get-TechIdAgents -AgentName $AgentName -Credential $Credential -ApiHost $ApiHost -ShowApiCall:$false
            }
            else { # ByGuid
                $identifyingParam = $DomainGuid
                Write-Verbose "Searching for agent record with DomainGuid '$DomainGuid'..."
                $agentToDelete = Get-TechIdAgents -DomainGuid $DomainGuid -Credential $Credential -ApiHost $ApiHost -ShowApiCall:$false
            }
            
            if (-not $agentToDelete) {
                throw "Agent '$identifyingParam' not found."
            }
            if ($agentToDelete.Count -gt 1) {
                throw "Multiple agents found matching '$identifyingParam'. For safety, Remove-TechIdAgent requires a unique identifier. Please be more specific."
            }

            $agentGuid = $agentToDelete.DomainGuid
            $resolvedAgentName = $agentToDelete.Name
            Write-Verbose "Found agent '$resolvedAgentName' with GUID: $agentGuid"

            if ($PSCmdlet.ShouldProcess($resolvedAgentName, "Delete Agent Record (GUID: $agentGuid)")) {
                $apiRequest = @{
                    ApiHost               = $ApiHost
                    Credential            = $Credential
                    Endpoint              = "/client/domain"
                    Method                = 'DELETE'
                    AdditionalQueryParams = @{ DomainGuid = $agentGuid }
                    ShowApiCall           = $ShowApiCall
                    CallingFunction       = 'Remove-TechIdAgent'
                }
                Invoke-TechIdApiRequest @apiRequest

                Write-Host "Successfully deleted agent record '$resolvedAgentName'." -ForegroundColor Green
            }
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-Error "A fatal error occurred while trying to remove agent '$identifyingParam': $errorMessage"
        }
    }
}
