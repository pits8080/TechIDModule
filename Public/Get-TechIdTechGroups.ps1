function Get-TechIdTechGroups {
<#
.SYNOPSIS
    Retrieves technician groups from the TechID API.
.DESCRIPTION
    Connects to the TechID API and retrieves a complete list of all configured technician groups.
    If a specific name is provided, it will fetch the detailed properties for that single group, including its members.
.PARAMETER GroupName
    The name of a specific technician group to retrieve. If omitted, the function returns a summary list of all groups.
.PARAMETER MemberNames
    If specified, the function will return only the names of the members of the group(s).
.PARAMETER Credential
    A PSCredential object. If omitted, the function will look for a saved credential file.
.PARAMETER ApiHost
    The base URL for the TechID API endpoint. Defaults to 'https://ch010.ruffiansoftware.com'.
.PARAMETER ShowApiCall
    If specified, the function will display the raw API request details before execution.
.EXAMPLE
    PS C:\> Get-TechIdTechGroups

    Description:
    Automatically loads the saved credential and retrieves all technician groups from TechID.
.EXAMPLE
    PS C:\> Get-TechIdTechGroups -GroupName "Helpdesk"

    Description:
    Retrieves the full details for the "Helpdesk" group, including its members.
.EXAMPLE
    PS C:\> Get-TechIdTechGroups -GroupName "Helpdesk" -MemberNames

    Description:
    Retrieves only the names of the members of the "Helpdesk" group.
.NOTES
    Author:      Daniel Houle
    Date:        2025-09-03
    Version:     1.3.0

    VERSION HISTORY:
    1.3.0 - 2025-10-01 - Added -MemberNames switch to return only member names.
    1.2.0 - 2025-09-18 - Added logic to get detailed information for a single group by name.
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Alias('Name')]
        [string]$GroupName,

        [Parameter(Mandatory = $false)]
        [switch]$MemberNames,

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
            $result = if ([string]::IsNullOrEmpty($GroupName)) {
                # This GET request uses a body, which is non-standard. Handle as a special case.
                $apiKey = $Credential.GetNetworkCredential().Password; $managerEmail = $Credential.UserName
                $headers = @{ "Authorization" = "APIKey $apiKey"; "Accept" = "application/json" }
                $bodyParams = @{ Email = $managerEmail; authenticationmethod = "local" }
                $fullUrl = "$ApiHost/client/techgroup"

                if ($ShowApiCall) {
                    Write-Host "`n--- API Call Details (Get-TechIdTechGroups - All) ---" -ForegroundColor Yellow
                    Write-Host "Method: GET"
                    Write-Host "URL: $fullUrl"
                    $redactedHeaders = $headers.Clone(); if ($redactedHeaders.Authorization) { $redactedHeaders.Authorization = "APIKey ****" }
                    Write-Host "Headers:"
                    $redactedHeaders | Format-List | Out-Host
                    Write-Host "Body:"
                    $bodyParams | Format-List | Out-Host
                    Write-Host "----------------------------------------------------------" -ForegroundColor Yellow
                }
                Invoke-RestMethod -Uri $fullUrl -Headers $headers -Method Get -Body $bodyParams -ErrorAction Stop
            }
            else {
                # Don't pass ShowApiCall down, as it would create duplicate output.
                $allGroups = Get-TechIdTechGroups -Credential $Credential -ApiHost $ApiHost -ShowApiCall:$ShowApiCall
                $foundGroup = $allGroups | Where-Object { $_.Name -eq $GroupName }
                
                if (-not $foundGroup) {
                    throw "Technician group with name '$GroupName' not found."
                }
                
                # The techgroup endpoint does not appear to have a dedicated detail view; the main endpoint returns members.
                $foundGroup
            }

            if ($MemberNames) {
                if ($result) {
                    return $result.Members.Name
                }
            }
            else {
                return $result
            }
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-Error "A fatal error occurred while getting technician groups: $errorMessage"
        }
    }
}
