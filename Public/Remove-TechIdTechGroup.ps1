function Remove-TechIdTechGroup {
<#
.SYNOPSIS
    Deletes a technician group from the TechID portal, automatically removing members first.
.DESCRIPTION
    This command permanently deletes a registered technician group from TechID.
    It first finds all members of the group and removes them, then deletes the empty group.
    For safety, this command requires an exact name match and does not support wildcards.
    It fully supports the -WhatIf and -Confirm parameters.
.PARAMETER GroupName
    The full, exact name of the technician group to be deleted. This parameter is mandatory.
.EXAMPLE
    PS C:\> Remove-TechIdTechGroup -GroupName "Old Project Team" -WhatIf

    Description:
    Shows that it would first remove all members from the group and then delete the group itself, without actually performing the actions.
.NOTES
    Author:      Daniel Houle
    Date:        2025-10-02
    Version:     2.0.0
#>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Name')]
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
            Write-Verbose "Searching for technician group '$GroupName' to get its GUID..."
            $groupToDelete = Get-TechIdTechGroups -GroupName $GroupName -Credential $Credential -ApiHost $ApiHost -ShowApiCall:$false
            
            if (-not $groupToDelete) {
                throw "Technician group with name '$GroupName' not found."
            }

            # --- NEW LOGIC: Remove all members from the group first ---
            if ($null -ne $groupToDelete.Members) {
                Write-Host "Group '$GroupName' has $($groupToDelete.Members.Count) members. Removing them first..." -ForegroundColor Yellow
                foreach ($member in $groupToDelete.Members) {
                    # This calls the other function we built
                    Remove-TechIdTechFromGroup -TechnicianName $member.Name -GroupName $GroupName -Credential $Credential -ApiHost $ApiHost -ShowApiCall:$ShowApiCall
                }
            }

            $groupId = $groupToDelete.TechGroupId
            Write-Verbose "All members removed. Proceeding with deletion of group (GUID: $groupId)"

            if ($PSCmdlet.ShouldProcess($GroupName, "Delete Technician Group (GUID: $groupId)")) {
                
                # --- THIS IS THE KEY FIX for the 405 Error ---
                # The Group ID is now part of the Endpoint path, not a query parameter.
                $apiRequest = @{
                    ApiHost         = $ApiHost
                    Credential      = $Credential
                    Endpoint        = "/client/techgroup/$groupId" 
                    Method          = 'DELETE'
                    ShowApiCall     = $ShowApiCall
                    CallingFunction = 'Remove-TechIdTechGroup'
                }
                Invoke-TechIdApiRequest @apiRequest

                Write-Host "Successfully deleted technician group '$GroupName'." -ForegroundColor Green
            }
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-Error "A fatal error occurred while trying to remove technician group '$GroupName': $errorMessage"
        }
    }
}
