function Remove-TechIdTechFromGroup {
<#
.SYNOPSIS
    Removes a technician from a technician group.
.DESCRIPTION
    This command removes a specified technician from an existing technician group.
    It fully supports -WhatIf for safe testing.
.PARAMETER TechnicianName
    The full, exact name of the technician to remove from the group. This parameter supports pipeline input.
.PARAMETER GroupName
    The name of the technician group from which the technician will be removed. This parameter is mandatory.
.PARAMETER Credential
    A PSCredential object. If omitted, the function will look for a saved credential file.
.PARAMETER ApiHost
    The base URL for the TechID API endpoint. Defaults to 'https://ch010.ruffiansoftware.com'.
.PARAMETER ShowApiCall
    If specified, the function will display the raw API request details before execution.
.EXAMPLE
    PS C:\> Remove-TechIdTechFromGroup -TechnicianName "testuser" -GroupName "Helpdesk" -WhatIf

    Description:
    Shows that it would remove the technician "testuser" from the "Helpdesk" group. No actual changes are made.
.NOTES
    Author:      Daniel Houle
    Date:        2025-09-23
    Version:     1.0.0
#>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = 'Name')]
        [Alias('Name')]
        [string]$TechnicianName,

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
            $targetGroup = Get-TechIdTechGroups -GroupName $GroupName -Credential $Credential -ApiHost $ApiHost -ShowApiCall:$false
            if (-not $targetGroup) {
                throw "Technician group '$GroupName' not found."
            }

            # Step 2: Find the technician in the group's member list
            $technicianToRemove = $null
            if ($null -ne $targetGroup.Members) {
                $technicianToRemove = $targetGroup.Members | Where-Object { $_.Name -eq $TechnicianName }
            }

            if (-not $technicianToRemove) {
                Write-Host "Technician '$TechnicianName' is not a member of group '$GroupName'. No action needed." -ForegroundColor Yellow
                return
            }

            # Step 3: Prepare the API call
            $groupId = $targetGroup.TechGroupId
            $techId = $technicianToRemove.TechId
            
            if ($PSCmdlet.ShouldProcess("Group '$GroupName'", "Remove technician '$TechnicianName'")) {
                $apiRequest = @{
                    ApiHost         = $ApiHost
                    Credential      = $Credential
                    Endpoint        = "/client/techgroup/$groupId/tech/$techId"
                    Method          = 'DELETE'
                    ShowApiCall     = $ShowApiCall
                    CallingFunction = 'Remove-TechIdTechFromGroup'
                }
                Invoke-TechIdApiRequest @apiRequest

                Write-Host "Successfully removed technician '$TechnicianName' from group '$GroupName'." -ForegroundColor Green
            }
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-Error "A fatal error occurred while trying to remove technician '$TechnicianName' from group '$GroupName': $errorMessage"
        }
    }
}
