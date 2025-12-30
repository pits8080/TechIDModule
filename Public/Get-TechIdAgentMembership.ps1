function Get-TechIdAgentMembership {
<#
.SYNOPSIS
    Finds all agent groups that a specific agent belongs to.
.DESCRIPTION
    This is a helper function that performs a reverse lookup to determine group membership for an agent.
    It returns a custom object containing the agent's name and a list of the groups it is a member of.
.PARAMETER AgentName
    The name of the agent (e.g., the computer name) to find group memberships for. This parameter is mandatory.
.PARAMETER NoCache
    If specified, the function will not use the performance-enhancing cache and will query the API live for each agent.
.PARAMETER Credential
    A PSCredential object. If omitted, the function will look for a saved credential file.
.PARAMETER ApiHost
    The base URL for the TechID API endpoint. Defaults to the configured default host.
.PARAMETER ShowApiCall
    If specified, the function will display the raw API request details for its internal calls.
.EXAMPLE
    PS C:\> Get-TechIdAgentMembership -AgentName "SERVER01\Admin"

    Description:
    Checks all agent groups in TechID and returns the names of the groups that "SERVER01\Admin" is a member of.
.EXAMPLE
    PS C:\> Get-TechIdAgents -Name "SERVER01\Admin" | Get-TechIdAgentMembership

    Description:
    Finds the agent record for "SERVER01\Admin" and pipes it to this command to find its group memberships.
.NOTES
    Author:      Daniel Houle
    Date:        2025-09-04
    Version:     3.0.0

    VERSION HISTORY:
    1.9.0 - 2025-09-30 - Changed -UseCache to -NoCache to follow PowerShell best practices.
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Name')]
        [string]$AgentName,

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
            Write-Verbose "Initializing agent group cache... (This may take a moment)"
            $allGroupsSummary = Get-TechIdAgentGroups -Credential $Credential -ApiHost $ApiHost -ShowApiCall:$false
            $script:allGroupsWithMembersCache = foreach ($group in $allGroupsSummary) {
                if ($group.MembersCount -gt 0) {
                    Get-TechIdAgentGroups -Credential $Credential -ApiHost $ApiHost -GroupName $group.Name -ShowApiCall:$false
                }
            }
            Write-Verbose "Group cache created with $($script:allGroupsWithMembersCache.Count) groups with members."
        }
    }

    process {
        try {
            $foundInGroups = [System.Collections.Generic.List[string]]::new()

            if ($ShowApiCall) {
                Write-Host "`n--- API Call Details (Get-TechIdAgentMembership) ---" -ForegroundColor Yellow
                Write-Host "This function performs multiple API calls to build a membership map."
                Write-Host "To see individual API calls, run the underlying Get-TechIdAgentGroups command with -ShowApiCall."
                Write-Host "----------------------------------------------------" -ForegroundColor Yellow
            }

            if (-not $NoCache) {
                # --- FAST PATH: Use the pre-built cache ---
                foreach ($groupDetail in $script:allGroupsWithMembersCache) {
                    if ($null -ne $groupDetail.Members) {
                        foreach($member in $groupDetail.Members){
                            if ($member.Name -eq $AgentName) {
                                $foundInGroups.Add($groupDetail.Name)
                                break 
                            }
                        }
                    }
                }
            }
            else {
                # --- SLOW PATH: Query API for each agent (no cache) ---
                Write-Verbose "Cache disabled. Getting a summary list of all agent groups for '$AgentName'..."
                $allGroups = Get-TechIdAgentGroups -Credential $Credential -ApiHost $ApiHost -ShowApiCall:$false

                foreach ($groupSummary in $allGroups) {
                    if ($groupSummary.MembersCount -gt 0) {
                        Write-Verbose "Checking members of group '$($groupSummary.Name)'..."
                        $groupDetail = Get-TechIdAgentGroups -Credential $Credential -ApiHost $ApiHost -GroupName $groupSummary.Name -ShowApiCall:$false
                        
                        if ($null -ne $groupDetail.Members) {
                            foreach($member in $groupDetail.Members){
                                if($member.Name -eq $AgentName){
                                    $foundInGroups.Add($groupSummary.Name)
                                    break 
                                }
                            }
                        }
                    }
                }
            }
            
            $outputObject = [PSCustomObject]@{
                AgentName = $AgentName
                Groups    = $foundInGroups
            }
            Write-Output $outputObject
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-Error "A fatal error occurred while determining agent membership for '$AgentName': $errorMessage"
        }
    }
}
