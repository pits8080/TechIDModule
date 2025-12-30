function Set-TechIdAgentOptions {
<#
.SYNOPSIS
    Modifies the options for a single agent.
.DESCRIPTION
    This command updates one or more configuration options for a specific agent in TechID using the POST /client/agent/{AgentID}/options endpoint.
    It makes a single API call with all specified options.
.PARAMETER AgentName
    The full, exact name of the agent whose options you want to modify.
.PARAMETER DomainGuid
    The Domain GUID of the agent whose options you want to modify.
.PARAMETER InputObject
    An agent object piped from Get-TechIdAgents.
.PARAMETER JustInTime
    Enables or disables Just-In-Time access. Valid values are '0' (Disabled) and '1' (Enabled).
.PARAMETER RotationEnabled
    Enables or disables password rotation. Valid values are 'Yes', 'No'.
.PARAMETER RotationFrequencyDays
    Sets the rotation frequency in days. Valid values are integers from 1 to 365.
.PARAMETER AccountDescription
    Sets the account description for the agent.
.PARAMETER OU
    Sets the Organizational Unit for the agent.
.PARAMETER UserName
    Sets the username format for the agent.
.PARAMETER HourToRun
    Sets the hour of the day for scheduled tasks (00-23).
.PARAMETER AccountType
    Sets the account type for the agent.
.PARAMETER CanForcePasswordRotation
    Specifies if password rotation can be forced. Valid values are 'Yes', 'No'.
.EXAMPLE
    PS C:\> Set-TechIdAgentOptions -AgentName "AGENT01\Admin" -JustInTime "1" -WhatIf

    Description:
    Shows what would happen if you enabled Just-In-Time access for the agent "AGENT01\Admin".
.EXAMPLE
    PS C:\> Get-TechIdAgents -DomainGuid "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" | Set-TechIdAgentOptions -RotationEnabled "Yes"

    Description:
    Enables password rotation for the agent identified by its Domain GUID, passed via the pipeline.
.NOTES
    Author:      Daniel Houle
    Date:        2025-10-22
    Version:     3.0.0

    VERSION HISTORY:
    1.4.0 - 2025-10-22 - Enabled pipeline support by property name for DomainGuid and AgentName parameters.
    1.3.0 - 2025-10-09 - Added InputObject parameter set to correctly handle pipeline input.
    1.2.0 - 2025-10-09 - Added DomainGuid parameter set.
    1.1.0 - 2025-10-08 - Initial release.
#>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium', DefaultParameterSetName = 'ByName')]
    param(
        [Parameter(ParameterSetName = 'ByInputObject', Mandatory = $true, ValueFromPipeline = $true)]
        [psobject]$InputObject,

        [Parameter(ParameterSetName = 'ByName', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Name')]
        [string]$AgentName,

        [Parameter(ParameterSetName = 'ByGuid', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$DomainGuid,

        [Parameter(Mandatory = $false)]
        [ValidateSet('0', '1')]
        [string]$JustInTime,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Yes', 'No')]
        [string]$RotationEnabled,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 365)]
        [int]$RotationFrequencyDays,
        
        [Parameter(Mandatory=$false)]
        [string]$AccountDescription,

        [Parameter(Mandatory=$false)]
        [string]$OU,

        [Parameter(Mandatory=$false)]
        [string]$UserName,

        [Parameter(Mandatory=$false)]
        [ValidateRange(0,23)]
        [string]$HourToRun,

        [Parameter(Mandatory=$false)]
        [string]$AccountType,

        [Parameter(Mandatory=$false)]
        [ValidateSet('Yes', 'No')]
        [string]$CanForcePasswordRotation,

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

        # This mapping translates the PowerShell parameter name to the exact API property name.
        $script:paramToApiMap = @{
            JustInTime               = 'JustInTime'
            RotationEnabled       = 'RotationEnabled'
            RotationFrequencyDays = 'RotationFrequencyDays'
            AccountDescription    = 'AccountDescription'
            OU                    = 'OU'
            UserName              = 'UserName'
            HourToRun             = 'HourToRun'
            AccountType           = 'AccountType'
            CanForcePasswordRotation = 'CanForcePasswordRotation'
        }
    }

    process {
        try {
            $agent = $null
            $identifyingParam = $null

            # Determine the agent to modify based on the parameters provided.
            if ($PSBoundParameters.ContainsKey('InputObject')) {
                $identifyingParam = $InputObject.Name
                # If the piped object has a DomainGuid, it's the most reliable identifier.
                if ($InputObject.PSObject.Properties.Name -contains 'DomainGuid' -and -not [string]::IsNullOrEmpty($InputObject.DomainGuid)) {
                    Write-Verbose "Piped object has DomainGuid. Looking up agent by GUID: $($InputObject.DomainGuid)"
                    $agent = Get-TechIdAgents -DomainGuid $InputObject.DomainGuid -Credential $Credential -ApiHost $ApiHost
                }
                # If it's a full agent object from Get-TechIdAgents, it will have DomainId.
                elseif ($InputObject.PSObject.Properties.Name -contains 'DomainId') {
                    Write-Verbose "Piped object appears to be a full agent object from Get-TechIdAgents. Using it directly."
                    $agent = $InputObject
                }
                # Fallback for other piped objects with just a name.
                else {
                    Write-Verbose "Piped object only has a name. Looking up agent by name: '$identifyingParam'"
                    $agent = Get-TechIdAgents -AgentName $identifyingParam -Credential $Credential -ApiHost $ApiHost
                }
            }
            elseif ($PSBoundParameters.ContainsKey('DomainGuid')) {
                $identifyingParam = $DomainGuid
                Write-Verbose "Finding agent with GUID '$DomainGuid'..."
                $agent = Get-TechIdAgents -DomainGuid $DomainGuid -Credential $Credential -ApiHost $ApiHost
            }
            elseif ($PSBoundParameters.ContainsKey('AgentName')) {
                $identifyingParam = $AgentName
                Write-Verbose "Finding agent '$AgentName' to get its ID..."
                $agent = Get-TechIdAgents -AgentName $AgentName -Credential $Credential -ApiHost $ApiHost
            }

            # --- Validation ---
            if (-not $agent) { throw "Agent '$identifyingParam' not found." }
            if ($agent.Count -gt 1) { throw "Multiple agents found matching '$identifyingParam'. Please provide a unique name or use -DomainGuid." }

            $agentId = $agent.DomainId
            $resolvedAgentName = $agent.Name
            Write-Verbose "Found agent '$resolvedAgentName' with ID: $agentId"

            $bodyPayload = @{}
            $changes = @()

            foreach ($paramName in $PSBoundParameters.Keys) {
                if ($script:paramToApiMap.ContainsKey($paramName)) {
                    $apiPropertyName = $script:paramToApiMap[$paramName]
                    $apiPropertyValue = $PSBoundParameters[$paramName].ToString()
                    $bodyPayload[$apiPropertyName] = $apiPropertyValue
                    $changes += "Set option '$apiPropertyName' to '$apiPropertyValue'"
                }
            }

            if ($bodyPayload.Count -eq 0) {
                Write-Warning "No options were specified to set. No action will be taken."
                return
            }

            if ($PSCmdlet.ShouldProcess("Agent '$resolvedAgentName'", ($changes -join ", "))) {
                $apiRequest = @{
                    ApiHost         = $ApiHost
                    Credential      = $Credential
                    Endpoint        = "/client/agent/$agentId/options"
                    Method          = 'POST'
                    Body            = $bodyPayload
                    ShowApiCall     = $ShowApiCall
                    CallingFunction = 'Set-TechIdAgentOptions'
                }
                Invoke-TechIdApiRequest @apiRequest

                Write-Host "Successfully updated options for agent '$resolvedAgentName'." -ForegroundColor Green
            }
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-Error "A fatal error occurred while trying to set options for agent '$identifyingParam': $errorMessage"
        }
    }
}
