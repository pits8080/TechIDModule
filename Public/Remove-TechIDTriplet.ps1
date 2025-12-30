function Remove-TechIDTriplet {
    <#
    .SYNOPSIS
        Removes a TechGroupRightGroupDomainGroup (Triplet) relationship.

    .DESCRIPTION
        The Remove-TechIDTriplet cmdlet deletes an existing triplet.
        You can specify the triplet by its ID, Name, or via pipeline input.

    .PARAMETER Id
        The ID (TechGroupRightGroupDomainGroupId) of the Triplet to remove.

    .PARAMETER Name
        The Name of the Triplet to remove. The function will look up the ID based on the name.

    .PARAMETER InputObject
        A Triplet object piped from Get-TechIDTriplet.

    .PARAMETER Credential
        A PSCredential object. If omitted, the function will look for a saved credential file.

    .PARAMETER ApiHost
        The base URL for the TechID API endpoint. Defaults to the configured default host.

    .PARAMETER ShowApiCall
        If specified, the full API URL and headers will be displayed in the console (secrets redacted).

    .EXAMPLE
        Remove-TechIDTriplet -Id 123
        Removes the triplet with ID 123.

    .EXAMPLE
        Remove-TechIDTriplet -Name "My Triplet"
        Finds the triplet named "My Triplet" and removes it.

    .EXAMPLE
        Get-TechIDTriplet -Name "My Triplet" | Remove-TechIDTriplet
        Removes the triplet piped from Get-TechIDTriplet.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ById')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'ById', Position = 0, ValueFromPipelineByPropertyName = $true)]
        [Alias('TechGroupRightGroupDomainGroupId')]
        [int]$Id,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByGuid')]
        [Guid]$TripletGuid,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByName')]
        [string]$Name,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByInputObject', ValueFromPipeline = $true)]
        [PSObject]$InputObject,

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
        if ($PSCmdlet.ParameterSetName -eq 'ByInputObject') {
            if ($InputObject.PSObject.Properties['TechGroupRightGroupDomainGroupId']) {
                $Id = $InputObject.TechGroupRightGroupDomainGroupId
            }
            else {
                Write-Error "Input object does not have a 'TechGroupRightGroupDomainGroupId' property."
                return
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'ByName') {
            $triplet = Get-TechIDTriplet -Name $Name -Credential $Credential -ApiHost $ApiHost
            if (-not $triplet) {
                Write-Error "Triplet with name '$Name' not found."
                return
            }
            if ($triplet.Count -gt 1) {
                Write-Error "Multiple triplets found with name '$Name'. Please use ID or refine the name."
                return
            }
            $Id = $triplet.TechGroupRightGroupDomainGroupId
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'ByGuid') {
            # API requires integer ID, so we must look it up
            $allTriplets = Get-TechIDTriplet -Credential $Credential -ApiHost $ApiHost
            $triplet = $allTriplets | Where-Object { $_.TripletGuid -eq $TripletGuid.ToString() }
            
            if (-not $triplet) {
                Write-Error "Triplet with GUID '$TripletGuid' not found."
                return
            }
            $Id = $triplet.TechGroupRightGroupDomainGroupId
        }

        $endpoint = "/client/techgrouprightgroupdomaingroup/$Id"

        if ($PSCmdlet.ShouldProcess("Triplet ID: $Id", "Remove Triplet")) {
            # Use the internal helper to make the API call
            Invoke-TechIdApiRequest -ApiHost $ApiHost -Credential $Credential -Method DELETE -Endpoint $endpoint -ShowApiCall:$ShowApiCall -CallingFunction "Remove-TechIDTriplet"
        }
    }
}
