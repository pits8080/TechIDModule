function Get-TechIdTechMembership {
<#
.SYNOPSIS
    Finds all technician groups that a specific technician belongs to.
.DESCRIPTION
    This is a helper function that performs a reverse lookup to determine group membership for a technician.
    It returns a custom object containing the technician's name and a list of the groups they are a member of.
.PARAMETER TechnicianName
    The name of the technician to find group memberships for. This parameter is mandatory and supports pipeline input.
.PARAMETER NoCache
    If specified, the function will not use the performance-enhancing cache and will query the API live for each technician.
.PARAMETER Credential
    A PSCredential object. If omitted, the function will look for a saved credential file.
.PARAMETER ApiHost
    The base URL for the TechID API endpoint. Defaults to the configured default host.
.PARAMETER ShowApiCall
    If specified, the function will display the raw API request details for its internal calls.
.EXAMPLE
    PS C:\> Get-TechIdTechMembership -TechnicianName "dantest"

    Description:
    Checks all technician groups and returns a list of the groups that "dantest" is a member of.
.EXAMPLE
    PS C:\> Get-TechIdTech -Name "dant*" | Get-TechIdTechMembership

    Description:
    Finds all technicians whose name starts with "dant" and efficiently finds their group memberships.
.NOTES
    Author:      Daniel Houle
    Date:        2025-09-18
    Version:     3.0.0
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Name')]
        [string]$TechnicianName,

        [Parameter(Mandatory = $false)]
        [switch]$NoCache,

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

        if (-not $NoCache) {
            # --- PERFORMANCE OPTIMIZATION: CACHE ---
            Write-Verbose "Initializing technician group cache... (This may take a moment)"
            $allGroupsSummary = Get-TechIdTechGroups -Credential $Credential -ApiHost $ApiHost -ShowApiCall:$false
            $script:allTechGroupsWithMembersCache = foreach ($group in $allGroupsSummary) {
                Get-TechIdTechGroups -Credential $Credential -ApiHost $ApiHost -GroupName $group.Name -ShowApiCall:$false
            }
            Write-Verbose "Group cache created with $($script:allTechGroupsWithMembersCache.Count) groups."
        }
    }

    process {
        try {
            $foundInGroups = [System.Collections.Generic.List[string]]::new()

            if ($ShowApiCall) {
                Write-Host "`n--- API Call Details (Get-TechIdTechMembership) ---" -ForegroundColor Yellow
                Write-Host "This function performs multiple API calls to build a membership map."
                Write-Host "To see individual API calls, run the underlying Get-TechIdTechGroups command with -ShowApiCall."
                Write-Host "----------------------------------------------------------" -ForegroundColor Yellow
            }

            if (-not $NoCache) {
                # --- FAST PATH: Use the pre-built cache ---
                foreach ($groupDetail in $script:allTechGroupsWithMembersCache) {
                    if ($null -ne $groupDetail.Members) {
                        foreach($member in $groupDetail.Members){
                            if ($member.Name -eq $TechnicianName) {
                                $foundInGroups.Add($groupDetail.Name)
                                break 
                            }
                        }
                    }
                }
            }
            else {
                # --- SLOW PATH: Query API for each technician (no cache) ---
                Write-Verbose "Cache disabled. Getting all technician groups for '$TechnicianName'..."
                $allGroups = Get-TechIdTechGroups -Credential $Credential -ApiHost $ApiHost -ShowApiCall:$false

                foreach ($groupDetail in $allGroups) {
                    if ($null -ne $groupDetail.Members) {
                        foreach($member in $groupDetail.Members){
                            if($member.Name -eq $TechnicianName){
                                $foundInGroups.Add($groupDetail.Name)
                                break 
                            }
                        }
                    }
                }
            }
            
            $outputObject = [PSCustomObject]@{
                TechnicianName = $TechnicianName
                Groups         = $foundInGroups
            }
            Write-Output $outputObject
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-Error "A fatal error occurred while determining technician membership for '$TechnicianName': $errorMessage"
        }
    }
}
