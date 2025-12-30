function Get-TechIDRightsGroup {
    <#
    .SYNOPSIS
        Retrieves TechID Rights Groups.

    .DESCRIPTION
        The Get-TechIDRightsGroup cmdlet retrieves information about Rights Groups.
        You can retrieve all rights groups or a specific one by its ID.

    .PARAMETER Id
        The ID of the Rights Group to retrieve. If omitted, all rights groups are returned.

    .PARAMETER Credential
        A PSCredential object. If omitted, the function will look for a saved credential file.

    .PARAMETER ApiHost
        The base URL for the TechID API endpoint. Defaults to 'https://ch010.ruffiansoftware.com'.

    .PARAMETER ShowApiCall
        If specified, the full API URL and headers will be displayed in the console (secrets redacted).

    .PARAMETER NoCache
        If specified, forces a live API query, bypassing any local caching (if applicable).

    .EXAMPLE
        Get-TechIDRightsGroup
        Retrieves all rights groups.

    .EXAMPLE
        Get-TechIDRightsGroup -Id 1
        Retrieves the rights group with ID 1.
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
        [string]$ApiHost = "https://ch010.ruffiansoftware.com",

        [Parameter(Mandatory = $false)]
        [switch]$ShowApiCall,

        [Parameter(Mandatory = $false)]
        [switch]$NoCache,

        [Parameter(Mandatory = $false)]
        [switch]$DisplayRights
    )

    begin {
        $Credential = Get-TechIdCredentialInternal -Credential $Credential
    }

    process {
        $endpoint = "/client/rightgroup"
        
        if ($PSCmdlet.ParameterSetName -eq 'ById' -and $PSBoundParameters.ContainsKey('Id')) {
            $endpoint = "$endpoint/$Id"
        }

        # Use the internal helper to make the API call
        $response = Invoke-TechIdApiRequest -ApiHost $ApiHost -Credential $Credential -Method GET -Endpoint $endpoint -ShowApiCall:$ShowApiCall -CallingFunction "Get-TechIDRightsGroup"

        if ($PSCmdlet.ParameterSetName -eq 'ByName' -and -not [string]::IsNullOrEmpty($Name)) {
            $response = $response | Where-Object { $_.Name -like $Name }
        }

        if ($DisplayRights) {
            return $response.Members
        }

        # Explicitly return the response to ensure array unrolling
        return $response
    }
}
