function Get-TechIdAgents {
    <#
.SYNOPSIS
    Retrieves registered agent records (domains) from the TechID API.
.DESCRIPTION
    Connects to the TechID API to retrieve a list of all agent records (referred to as domains by the API).
    If a name is provided, it will filter the results to return only that specific agent record. Wildcards (*, ?) are supported.
.PARAMETER AgentName
    The name of a specific agent to retrieve (e.g., "DHOULEDEVTESTVM\VisorySU"). This parameter supports wildcards (*, ?). If omitted, the function returns all agents.
.PARAMETER DomainGuid
    The unique Domain GUID of a specific agent to retrieve.
.PARAMETER Credential
    A PSCredential object. If omitted, the function will look for a saved credential file.
.PARAMETER ApiHost
    The base URL for the TechID API endpoint. Defaults to 'https://ch010.ruffiansoftware.com'.
.PARAMETER ShowApiCall
    If specified, the function will display the raw API request details before execution.
.EXAMPLE
    PS C:\> Get-TechIdAgents

    Description:
    Automatically loads the saved credential and retrieves all agent records from TechID.
.EXAMPLE
    PS C:\> Get-TechIdAgents -AgentName "DHOULEDEVTESTVM*"

    Description:
    Retrieves all agent records that start with "DHOULEDEVTESTVM".
.EXAMPLE
    PS C:\> Get-TechIdAgents -DomainGuid "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

    Description:
    Retrieves the agent record with the specified Domain GUID.
.NOTES
    Author:      Daniel Houle
    Date:        2025-09-04
    Version:     1.7.0

    VERSION HISTORY:
    1.7.0 - 2025-10-07 - Added -DomainGuid parameter to allow fetching by GUID.
    1.6.0 - 2025-09-12 - Added -ShowApiCall switch for debugging.
#>
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = 'ByName')]
        [string]$AgentName,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByGuid')]
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
            # Note: We are NOT using the Invoke-TechIdApiRequest helper here because this specific endpoint requires
            # a body on a GET request (non-standard) AND expects 'application/x-www-form-urlencoded' rather than JSON.
            # Invoke-TechIdApiRequest enforces JSON bodies and appends standard auth params to the QueryString,
            # which breaks this specific call.

            # Retrieve credentials
            $apiKey = $Credential.GetNetworkCredential().Password
            $managerEmail = $Credential.UserName

            # Build Request
            $headers = @{ "Authorization" = "APIKey $apiKey"; "Accept" = "application/json" }
            $bodyParams = @{ Email = $managerEmail; authenticationmethod = "local" }
            $fullUrl = "$ApiHost/client/domains"

            if ($ShowApiCall) {
                Write-Host "`n--- API Call Details (Get-TechIdAgents) ---" -ForegroundColor Yellow
                Write-Host "Method: GET"
                Write-Host "URL: $fullUrl"
                $redactedHeaders = $headers.Clone()
                if ($redactedHeaders.Authorization) { $redactedHeaders.Authorization = "APIKey ****" }
                Write-Host "Headers:"
                $redactedHeaders | Format-List | Out-Host
                Write-Host "Body (Form-UrlEncoded):"
                $bodyParams | Format-List | Out-Host
                Write-Host "--------------------------------------------" -ForegroundColor Yellow
            }
            
            Write-Verbose "Connecting to API to get agent records: $fullUrl"
            $apiResult = Invoke-RestMethod -Uri $fullUrl -Headers $headers -Method Get -Body $bodyParams -ErrorAction Stop
            
            if ($PSCmdlet.ParameterSetName -eq 'ByName' -and -not [string]::IsNullOrEmpty($AgentName)) {
                Write-Verbose "Filtering for agent record(s) matching pattern: $AgentName"
                $apiResult = $apiResult | Where-Object { $_.Name -like $AgentName }
            }
            elseif ($PSCmdlet.ParameterSetName -eq 'ByGuid') {
                Write-Verbose "Filtering for agent record with DomainGuid: $DomainGuid"
                $apiResult = $apiResult | Where-Object { $_.DomainGuid -eq $DomainGuid }
            }

            return $apiResult
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-Error "A fatal error occurred while getting agent records: $errorMessage"
        }
    }
}
