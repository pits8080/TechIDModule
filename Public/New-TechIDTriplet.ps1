function New-TechIDTriplet {
    <#
    .SYNOPSIS
        Creates a new TechGroupRightGroupDomainGroup (Triplet) relationship.

    .DESCRIPTION
        The New-TechIDTriplet cmdlet creates a new link between a Tech Group, a Rights Group, and a Domain Group.

    .PARAMETER TechGroupId
        The ID of the Tech Group.

    .PARAMETER RightGroupId
        The ID of the Rights Group.

    .PARAMETER DomainGroupId
        The ID of the Domain Group (Agent Group).

    .PARAMETER Credential
        A PSCredential object. If omitted, the function will look for a saved credential file.

    .PARAMETER ApiHost
        The base URL for the TechID API endpoint. Defaults to 'https://ch010.ruffiansoftware.com'.

    .PARAMETER ShowApiCall
        If specified, the full API URL and headers will be displayed in the console (secrets redacted).

    .EXAMPLE
        New-TechIDTriplet -TechGroupId 10 -RightGroupId 1 -DomainGroupId 5
        Creates a new triplet linking Tech Group 10, Rights Group 1, and Domain Group 5.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [int]$TechGroupId,

        [Parameter(Mandatory = $true)]
        [int]$RightGroupId,

        [Parameter(Mandatory = $true)]
        [int]$DomainGroupId,

        [Parameter(Mandatory = $false)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [DateTime]$Expiration,

        [Parameter(Mandatory = $false)]
        [switch]$NoExpiration,

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
        $endpoint = "/client/techgrouprightgroupdomaingroup/0"
        
        $body = @{
            TechGroup   = @{ TechGroupId = $TechGroupId }
            RightGroup  = @{ RightGroupId = $RightGroupId }
            DomainGroup = @{ DomainGroupId = $DomainGroupId }
        }

        if ($PSBoundParameters.ContainsKey('Name')) {
            $body['Name'] = $Name
        }
        if ($PSBoundParameters.ContainsKey('Description')) {
            $body['Description'] = $Description
        }
        
        if ($NoExpiration) {
            $body['Expiration'] = $null
        }
        elseif ($PSBoundParameters.ContainsKey('Expiration')) {
            $body['Expiration'] = $Expiration.ToString("yyyy-MM-ddTHH:mm:ss")
        }
        else {
            # Default to 1 year from now if not provided and NoExpiration not specified
            $body['Expiration'] = (Get-Date).AddYears(1).ToString("yyyy-MM-ddTHH:mm:ss")
        }

        if ($PSCmdlet.ShouldProcess("TechGroupId: $TechGroupId, RightGroupId: $RightGroupId, DomainGroupId: $DomainGroupId", "Create Triplet")) {
            # Use the internal helper to make the API call
            Invoke-TechIdApiRequest -ApiHost $ApiHost -Credential $Credential -Method POST -Endpoint $endpoint -Body $body -ShowApiCall:$ShowApiCall -CallingFunction "New-TechIDTriplet"
        }
    }
}
