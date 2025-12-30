function Get-TechIDTriplet {
    <#
    .SYNOPSIS
        Retrieves TechGroupRightGroupDomainGroup (Triplet) information.

    .DESCRIPTION
        The Get-TechIDTriplet cmdlet retrieves information about TechGroupRightGroupDomainGroup relationships.
        You can retrieve all triplets or a specific triplet by its ID.

    .PARAMETER Id
        The ID of the Triplet to retrieve. If omitted, all triplets are returned.

    .PARAMETER Credential
        A PSCredential object. If omitted, the function will look for a saved credential file.

    .PARAMETER ApiHost
        The base URL for the TechID API endpoint. Defaults to the configured default host.

    .PARAMETER ShowApiCall
        If specified, the full API URL and headers will be displayed in the console (secrets redacted).

    .PARAMETER NoCache
        If specified, forces a live API query, bypassing any local caching (if applicable).

    .EXAMPLE
        Get-TechIDTriplet
        Retrieves all triplets.

    .EXAMPLE
        Get-TechIDTriplet -Id 123
        Retrieves the triplet with ID 123.
    #>
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = 'ById', Position = 0)]
        [int]$Id,

        [Parameter(Mandatory = $false, ParameterSetName = 'ByName', Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(Mandatory = $false)]
        [string]$ApiHost,

        [Parameter(Mandatory = $false)]
        [switch]$ShowApiCall,

        [Parameter(Mandatory = $false)]
        [switch]$NoCache
    )

    begin {
        $Credential = Get-TechIdCredentialInternal -Credential $Credential
        if ([string]::IsNullOrWhiteSpace($ApiHost)) {
            $ApiHost = $script:DefaultApiHost
        }
    }

    process {
        $endpoint = "/client/techgrouprightgroupdomaingroup"
        
        if ($PSCmdlet.ParameterSetName -eq 'ById' -and $PSBoundParameters.ContainsKey('Id')) {
            $endpoint = "$endpoint/$Id"
        }
        
        # Use the internal helper to make the API call
        $response = Invoke-TechIdApiRequest -ApiHost $ApiHost -Credential $Credential -Method GET -Endpoint $endpoint -ShowApiCall:$ShowApiCall -CallingFunction "Get-TechIDTriplet"
        
        if ($PSCmdlet.ParameterSetName -eq 'ByName' -and -not [string]::IsNullOrEmpty($Name)) {
            $response = $response | Where-Object { $_.Name -like $Name }
        }

        # Explicitly return the response to ensure array unrolling
        return $response
    }
}
