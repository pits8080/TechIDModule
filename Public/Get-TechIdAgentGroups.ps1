function Get-TechIdAgentGroups {
<#
.SYNOPSIS
    Retrieves agent groups from the TechID API.
.DESCRIPTION
    Connects to the TechID API to retrieve a list of all configured agent groups.
    If a specific name is provided, it will fetch the detailed properties for that single group, including its members.
.PARAMETER GroupName
    The name of a specific agent group to retrieve. If omitted, the function returns a summary list of all groups.
.PARAMETER MemberNames
    If specified, the function will return only the names of the members of the group(s).
.PARAMETER Credential
    A PSCredential object. If omitted, the function will look for a saved credential file.
.PARAMETER ApiHost
    The base URL for the TechID API endpoint. Defaults to the configured default host.
.PARAMETER ShowApiCall
    If specified, the function will display the raw API request details before execution.
.EXAMPLE
    PS C:\> Get-TechIdAgentGroups

    Description:
    Retrieves a summary list of all agent groups.
.EXAMPLE
    PS C:\> Get-TechIdAgentGroups -GroupName "MSP-Domain-Shared"

    Description:
    Retrieves the full details for the "MSP-Domain-Shared" group, including its members.
.EXAMPLE
    PS C:\> Get-TechIdAgentGroups -GroupName "MSP-Domain-Shared" -MemberNames

    Description:
    Retrieves only the names of the members of the "MSP-Domain-Shared" group.
.NOTES
    Author:      Daniel Houle
    Date:        2025-10-02
    Version:     3.0.0

    VERSION HISTORY:
    1.5.0 - 2025-10-02 - Added -MemberNames switch to return only member names.
    1.4.0 - 2025-09-12 - Added -ShowApiCall switch for debugging.
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
            # This GET request uses a body, which is non-standard. Handle as a special case.
            $apiKey = $Credential.GetNetworkCredential().Password; $managerEmail = $Credential.UserName
            $headers = @{ "Authorization" = "APIKey $apiKey"; "Accept" = "application/json" }
            $bodyParams = @{ Email = $managerEmail; authenticationmethod = "local" }

            $result = if ([string]::IsNullOrEmpty($GroupName)) {
                $fullUrl = "$ApiHost/client/agentgroup"
                
                if ($ShowApiCall) {
                    Write-Host "`n--- API Call Details (Get-TechIdAgentGroups - All) ---" -ForegroundColor Yellow
                    Write-Host "Method: GET"
                    Write-Host "URL: $fullUrl"
                    $redactedHeaders = $headers.Clone(); if ($redactedHeaders.Authorization) { $redactedHeaders.Authorization = "APIKey ****" }
                    Write-Host "Headers:"
                    $redactedHeaders | Format-List | Out-Host
                    Write-Host "Body:"
                    $bodyParams | Format-List | Out-Host
                    Write-Host "----------------------------------------------------" -ForegroundColor Yellow
                }

                Write-Verbose "Connecting to API to get all agent groups: $fullUrl"
                Invoke-RestMethod -Uri $fullUrl -Headers $headers -Method Get -Body $bodyParams -ErrorAction Stop
            }
            else {
                Write-Verbose "Getting all agent groups to find '$GroupName'..."
                # Do not pass MemberNames here, as we need the full group object first.
                $allGroups = Get-TechIdAgentGroups -Credential $Credential -ApiHost $ApiHost -ShowApiCall:$ShowApiCall

                $foundGroup = $allGroups | Where-Object { $_.Name -eq $GroupName }

                if (-not $foundGroup) {
                    throw "Agent group with name '$GroupName' not found."
                }
                
                $groupId = $foundGroup.DomainGroupId
                $detailEndpoint = "/client/agentgroup/$groupId"
                $fullUrl = "$ApiHost$detailEndpoint"
                
                if ($ShowApiCall) {
                    Write-Host "`n--- API Call Details (Get-TechIdAgentGroups - Single) ---" -ForegroundColor Yellow
                    Write-Host "Method: GET"
                    Write-Host "URL: $fullUrl"
                    $redactedHeaders = $headers.Clone(); if ($redactedHeaders.Authorization) { $redactedHeaders.Authorization = "APIKey ****" }
                    Write-Host "Headers:"
                    $redactedHeaders | Format-List | Out-Host
                    Write-Host "Body:"
                    $bodyParams | Format-List | Out-Host
                    Write-Host "-------------------------------------------------------" -ForegroundColor Yellow
                }

                Write-Verbose "Found group. Connecting to detail endpoint: $fullUrl"
                Invoke-RestMethod -Uri $fullUrl -Headers $headers -Method Get -Body $bodyParams -ErrorAction Stop
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
            Write-Error "A fatal error occurred while getting agent groups: $errorMessage"
        }
    }
}
