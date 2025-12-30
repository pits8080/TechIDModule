function Set-TechIDTripletOption {
    <#
    .SYNOPSIS
        Sets options for a TechGroupRightGroupDomainGroup (Triplet).

    .DESCRIPTION
        The Set-TechIDTripletOption cmdlet modifies the configuration of a specific Triplet.
        Since the specific options are not fully documented in the schema, this function accepts a hashtable of options.

    .PARAMETER Id
        The ID of the Triplet to modify.

    .PARAMETER Options
        A hashtable of options to set. These will be converted to JSON and sent in the request body.

    .PARAMETER Credential
        A PSCredential object. If omitted, the function will look for a saved credential file.

    .PARAMETER ApiHost
        The base URL for the TechID API endpoint. Defaults to 'https://ch010.ruffiansoftware.com'.

    .PARAMETER ShowApiCall
        If specified, the full API URL and headers will be displayed in the console (secrets redacted).

    .EXAMPLE
        Set-TechIDTripletOption -Id 123 -Options @{ "AllowExport" = $true }
        Sets the "AllowExport" option to true for triplet 123.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [int]$Id,

        [Parameter(Mandatory = $true, Position = 1)]
        [hashtable]$Options,

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
        $endpoint = "/client/techgrouprightgroupdomaingroup/$Id"
        
        if ($PSCmdlet.ShouldProcess("Triplet ID: $Id", "Set Options: $($Options | ConvertTo-Json -Compress)")) {
            # Use the internal helper to make the API call
            Invoke-TechIdApiRequest -ApiHost $ApiHost -Credential $Credential -Method POST -Endpoint $endpoint -Body $Options -ShowApiCall:$ShowApiCall -CallingFunction "Set-TechIDTripletOption"
        }
    }
}
