function Get-TechIdAPIKeys {
    <#
.SYNOPSIS
    Retrieves the list of API keys for the current account.
.DESCRIPTION
    Connects to the TechID API to retrieve all API keys associated with the authenticated account.
.PARAMETER Credential
    A PSCredential object. If omitted, the function will look for a saved credential file.
.PARAMETER ApiHost
    The base URL for the TechID API endpoint. Defaults to 'https://ch010.ruffiansoftware.com'.
.PARAMETER ShowApiCall
    If specified, the function will display the raw API request details before execution.
.EXAMPLE
    PS C:\> Get-TechIdAPIKeys
    
    Description:
    Retrieves all API keys.
.NOTES
    Author:      Daniel Houle
    Date:        2025-11-25
    Version:     1.0.0
#>
    [CmdletBinding()]
    param (
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
            # This GET request uses a body, which is non-standard but required by this API.
            $apiKey = $Credential.GetNetworkCredential().Password
            $managerEmail = $Credential.UserName
            
            $headers = @{
                "Authorization" = "APIKey $apiKey"
                "Accept"        = "application/json"
            }

            $bodyParams = @{
                Email                = $managerEmail
                authenticationmethod = "local"
            }

            $fullUrl = "$ApiHost/client/account/apikey"

            if ($ShowApiCall) {
                Write-Host "`n--- API Call Details (Get-TechIdAPIKeys) ---" -ForegroundColor Yellow
                Write-Host "Method: GET"
                Write-Host "URL: $fullUrl"
                $redactedHeaders = $headers.Clone(); if ($redactedHeaders.Authorization) { $redactedHeaders.Authorization = "APIKey ****" }
                Write-Host "Headers:"; $redactedHeaders | Format-List | Out-Host
                Write-Host "Body:"; $bodyParams | Format-List | Out-Host
                Write-Host "----------------------------------------------" -ForegroundColor Yellow
            }

            # Using Invoke-RestMethod directly because Invoke-TechIdApiRequest might not handle GET with Body correctly without modification
            # or if it does, it's safer to follow the pattern established in Get-TechIdLeaf for these specific endpoints.
            $apiResult = Invoke-RestMethod -Uri $fullUrl -Headers $headers -Method Get -Body $bodyParams -ErrorAction Stop

            return $apiResult
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-Error "A fatal error occurred while retrieving API keys: $errorMessage"
        }
    }
}
