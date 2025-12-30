function Get-TechIdLeaf {
    <#
.SYNOPSIS
    Retrieves all agent account leafs from the TechID API.
.DESCRIPTION
    Connects to the TechID API and retrieves a complete list of all configured agent account leafs.
.PARAMETER Credential
    A PSCredential object. If omitted, the function will look for a saved credential file.
.PARAMETER ApiHost
    The base URL for the TechID API endpoint. Defaults to 'https://ch010.ruffiansoftware.com'.
.PARAMETER ShowApiCall
    If specified, the function will display the raw API request details before execution.
.EXAMPLE
    PS C:\> Get-TechIdLeaf

    Description:
    Automatically loads the saved credential and retrieves all account leafs from TechID.
.NOTES
    Author:      Daniel Houle
    Date:        2025-09-03
    Version:     1.1.0

    VERSION HISTORY:
    1.1.0 - 2025-09-12 - Added -ShowApiCall switch for debugging.
    1.0.0 - 2025-09-03 - Initial function creation.
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [Alias('Name')]
        [string]$Path,

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
            # This GET request uses a body, which is non-standard. Handle as a special case.
            $apiKey = $Credential.GetNetworkCredential().Password; $managerEmail = $Credential.UserName
            $headers = @{ "Authorization" = "APIKey $apiKey"; "Accept" = "application/json" }
            $bodyParams = @{ Email = $managerEmail; authenticationmethod = "local" }
            $fullUrl = "$ApiHost/client/accountleaf"

            if ($ShowApiCall) {
                Write-Host "`n--- API Call Details (Get-TechIdLeaf) ---" -ForegroundColor Yellow; Write-Host "Method: GET"; Write-Host "URL: $fullUrl"
                $redactedHeaders = $headers.Clone(); if ($redactedHeaders.Authorization) { $redactedHeaders.Authorization = "APIKey ****" }
                Write-Host "Headers:"; $redactedHeaders | Format-List | Out-Host
                Write-Host "Body:"; $bodyParams | Format-List | Out-Host
                Write-Host "-------------------------------------------" -ForegroundColor Yellow
            }

            $apiResult = Invoke-RestMethod -Uri $fullUrl -Headers $headers -Method Get -Body $bodyParams -ErrorAction Stop
            
            if (-not [string]::IsNullOrEmpty($Path)) {
                Write-Verbose "Filtering results for leaves matching pattern: $Path"
                $apiResult = $apiResult | Where-Object { $_.Path -like $Path }
            }

            return $apiResult
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-Error "A fatal error occurred while getting leafs: $errorMessage"
        }
    }
}
