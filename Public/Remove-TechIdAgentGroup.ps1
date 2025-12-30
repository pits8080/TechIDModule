function Remove-TechIdAgentGroup {
<#
.SYNOPSIS
    Deletes an agent group from the TechID portal.
.DESCRIPTION
    This command permanently deletes a registered agent group from TechID.
    For safety, this command requires an exact name match and does not support wildcards.
    It fully supports the -WhatIf and -Confirm parameters.
.PARAMETER GroupName
    The full, exact name of the agent group to be deleted. This parameter is mandatory.
.PARAMETER Credential
    A PSCredential object. If omitted, the function will look for a saved credential file.
.PARAMETER ApiHost
    The base URL for the TechID API endpoint. Defaults to the configured default host.
.PARAMETER ShowApiCall
    If specified, the function will display the raw API request details before execution.
.EXAMPLE
    PS C:\> Remove-TechIdAgentGroup -GroupName "Old Servers" -WhatIf

    Description:
    Shows that it would delete the agent group for "Old Servers" without actually performing the deletion.
.NOTES
    Author:      Daniel Houle
    Date:        2025-09-23
    Version:     3.0.0
#>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Name')]
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
            Write-Verbose "Searching for agent group '$GroupName' to get its GUID..."
            $groupToDelete = Get-TechIdAgentGroups -GroupName $GroupName -Credential $Credential -ApiHost $ApiHost -ShowApiCall:$false
            
            if (-not $groupToDelete) {
                throw "Agent group with name '$GroupName' not found."
            }
            if ($groupToDelete.Count -gt 1) {
                throw "Multiple agent groups found matching '$GroupName'. For safety, Remove-TechIdAgentGroup requires a unique, exact name. Please be more specific."
            }

            $groupId = $groupToDelete.DomainGroupId
            Write-Verbose "Found agent group with GUID: $groupId"

            if ($PSCmdlet.ShouldProcess($GroupName, "Delete Agent Group (GUID: $groupId)")) {
                $apiRequest = @{
                    ApiHost               = $ApiHost
                    Credential            = $Credential
                    Endpoint              = "/client/agentgroup"
                    Method                = 'DELETE'
                    AdditionalQueryParams = @{ DomainGroupId = $groupId }
                    ShowApiCall           = $ShowApiCall
                    CallingFunction       = 'Remove-TechIdAgentGroup'
                }
                Invoke-TechIdApiRequest @apiRequest

                Write-Host "Successfully deleted agent group '$GroupName'." -ForegroundColor Green
            }
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-Error "A fatal error occurred while trying to remove agent group '$GroupName': $errorMessage"
        }
    }
}
