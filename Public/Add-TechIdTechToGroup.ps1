function Add-TechIdTechToGroup {
<#
.SYNOPSIS
    Adds a technician to a technician group.
.DESCRIPTION
    This command adds a specified technician to an existing technician group.
    It fully supports -WhatIf for safe testing.
.PARAMETER TechnicianName
    The full, exact name of the technician to add to the group. This parameter supports pipeline input.
.PARAMETER GroupName
    The name of the technician group to which the technician will be added. This parameter is mandatory.
.PARAMETER Credential
    A PSCredential object. If omitted, the function will look for a saved credential file.
.PARAMETER ApiHost
    The base URL for the TechID API endpoint. Defaults to the configured default host.
.PARAMETER ShowApiCall
    If specified, the function will display the raw API request details before execution.
.EXAMPLE
    PS C:\> Add-TechIdTechToGroup -TechnicianName "testuser" -GroupName "Helpdesk" -WhatIf

    Description:
    Shows that it would add the technician "testuser" to the "Helpdesk" group. No actual changes are made.
.NOTES
    Author:      Daniel Houle
    Date:        2025-09-23
    Version:     3.0.0
#>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = 'Name')]
        [Alias('Name')]
        [string]$TechnicianName,

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
            $targetGroup = Get-TechIdTechGroups -GroupName $GroupName -Credential $Credential -ApiHost $ApiHost -ShowApiCall:$false
            if (-not $targetGroup) {
                throw "Technician group '$GroupName' not found."
            }

            # Step 2: Get the technician object to be added
            $technicianToAdd = Get-TechIdTech -TechnicianName $TechnicianName -Credential $Credential -ApiHost $ApiHost -ShowApiCall:$false
            if (-not $technicianToAdd) {
                throw "Technician '$TechnicianName' not found."
            }
             if ($technicianToAdd.Count -gt 1) {
                throw "Multiple technicians found matching '$TechnicianName'. Please provide a unique name."
            }

            # Step 3: Check if the technician is already a member
            $isAlreadyMember = $false
            if ($null -ne $targetGroup.Members) {
                $isAlreadyMember = $targetGroup.Members.Name -contains $technicianToAdd.Name
            }

            if ($isAlreadyMember) {
                Write-Host "Technician '$TechnicianName' is already a member of group '$GroupName'. No action needed." -ForegroundColor Yellow
                return
            }

            # Step 4: Prepare the API call
            $groupId = $targetGroup.TechGroupId
            $techId = $technicianToAdd.TechId
            
            if ($PSCmdlet.ShouldProcess("Group '$GroupName'", "Add technician '$TechnicianName'")) {
                $apiRequest = @{
                    ApiHost         = $ApiHost
                    Credential      = $Credential
                    Endpoint        = "/client/techgroup/$groupId/tech/$techId"
                    Method          = 'POST'
                    Body            = @{}
                    ShowApiCall     = $ShowApiCall
                    CallingFunction = 'Add-TechIdTechToGroup'
                }
                Invoke-TechIdApiRequest @apiRequest

                Write-Host "Successfully added technician '$TechnicianName' to group '$GroupName'." -ForegroundColor Green
            }
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-Error "A fatal error occurred while trying to add technician '$TechnicianName' to group '$GroupName': $errorMessage"
        }
    }
}
