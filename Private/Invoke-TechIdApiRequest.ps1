function Invoke-TechIdApiRequest {
    <#
.SYNOPSIS
    Internal helper to execute all API calls to the TechID service.
.DESCRIPTION
    This function centralizes all API communication. It handles credential extraction,
    header and query string construction, API key redaction for debug output, and the
    actual Invoke-RestMethod call.
.INPUTS
    Takes a splatted hashtable of parameters for maximum flexibility.
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [string]$ApiHost,
        [Parameter(Mandatory = $true)] [System.Management.Automation.PSCredential]$Credential,
        [Parameter(Mandatory = $true)] [string]$Endpoint,
        [Parameter(Mandatory = $true)] [string]$Method,
        [Parameter(Mandatory = $false)] [hashtable]$Body,
        [Parameter(Mandatory = $false)] [hashtable]$AdditionalQueryParams,
        [Parameter(Mandatory = $false)] [switch]$ShowApiCall,
        [Parameter(Mandatory = $false)] [string]$CallingFunction
    )

    $apiKey = $Credential.GetNetworkCredential().Password
    $managerEmail = $Credential.UserName

    $headers = @{
        "Authorization" = "APIKey $apiKey"
        "Accept"        = "application/json"
    }
    if ($Method -in @('POST', 'PUT', 'PATCH')) {
        
        $headers["Content-Type"] = "application/json"
    }

    $queryParams = @{
        Email                = $managerEmail
        authenticationmethod = "local"
    }

    if ($AdditionalQueryParams) {
        foreach ($key in $AdditionalQueryParams.Keys) {
            $queryParams[$key] = $AdditionalQueryParams[$key]
        }
    }

    $queryStringItems = @()
    foreach ($key in $queryParams.Keys) { $queryStringItems += "$([System.Net.WebUtility]::UrlEncode($key))=$([System.Net.WebUtility]::UrlEncode($queryParams[$key]))" }
    $queryString = [string]::Join("&", $queryStringItems)
    $fullUrl = "$($ApiHost)$($Endpoint)?$($queryString)"

    if ($ShowApiCall) {
        Write-Host "`n--- API Call Details ($CallingFunction) ---" -ForegroundColor Yellow
        Write-Host "Method: $Method"
        Write-Host "URL: $fullUrl"
        $redactedHeaders = $headers.Clone(); if ($redactedHeaders.Authorization) { $redactedHeaders.Authorization = "APIKey ****" }
        Write-Host "Headers:"; $redactedHeaders | Format-List | Out-Host
        if ($Body) { Write-Host "Body:"; $Body | ConvertTo-Json -Depth 5 }
        Write-Host "------------------------------------------------" -ForegroundColor Yellow
    }
    
    $invokeParams = @{
        Uri         = $fullUrl
        Headers     = $headers
        Method      = $Method
        ErrorAction = 'Stop'
    }
    if ($Body) {
        $invokeParams.Body = ($Body | ConvertTo-Json -Depth 5)
    }

    return Invoke-RestMethod @invokeParams
}

#endregion
