function New-TechIdTech {
    <#
    .SYNOPSIS
        Creates a new technician in TechIDManager.
    .DESCRIPTION
        Creates a new technician by sending a request to the TechID API.
        It also supports adding the new technician to specified TechID Groups immediately after creation.
    .PARAMETER Name
        The username for the technician (e.g. 'jdoe'). This maps to the 'Name' property in the API.
    .PARAMETER FirstName
        The first name of the technician.
    .PARAMETER LastName
        The last name of the technician.
    .PARAMETER Email
        The email address of the technician.
    .PARAMETER Phone
        The phone number of the technician.
    .PARAMETER TechGroups
        A list of TechID Group names to add the new technician to.
    .PARAMETER Credential
        A PSCredential object. The username should be the manager's email and the password should be the TechID API Key.
        If omitted, the function will look for a saved credential file.
    .PARAMETER ApiHost
        The base URL for the TechID API endpoint. Defaults to the configured default host.
    .PARAMETER ShowApiCall
        If specified, the function will display the raw API request details before execution.
    .EXAMPLE
        PS C:\> New-TechIdTech -Name "jdoe" -FirstName "John" -LastName "Doe" -Email "jdoe@example.com" -TechGroups "Tier1Support","AllTechs"

        Description:
        Creates the technician 'jdoe' and adds them to the 'Tier1Support' and 'AllTechs' groups.
    .NOTES
        Author:      Daniel Houle
        Date:        2025-12-23
        Version:     3.0.0

        VERSION HISTORY:
        1.0.0 - 2025-12-23 - Initial creation.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [string]$FirstName,

        [Parameter(Mandatory = $false)]
        [string]$LastName,

        [Parameter(Mandatory = $false)]
        [string]$Email,

        [Parameter(Mandatory = $false)]
        [string]$Phone,

        [Parameter(Mandatory = $false)]
        [string[]]$TechGroups,

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
        # Construct the body for the technician creation request.
        # The 'Status' property must be set to 'new' for creation.
        $body = @{
            Name   = $Name
            Status = "new"
        }

        if ($PSBoundParameters.ContainsKey('FirstName')) { $body['FirstName'] = $FirstName }
        if ($PSBoundParameters.ContainsKey('LastName')) { $body['LastName'] = $LastName }
        if ($PSBoundParameters.ContainsKey('Email')) { $body['Email'] = $Email }
        if ($PSBoundParameters.ContainsKey('Phone')) { $body['Phone'] = $Phone }

        # The endpoint from the website: /client/tech/status
        $endpoint = "/client/tech/status"

        if ($PSCmdlet.ShouldProcess($Name, "Create TechID Technician")) {
            try {
                Invoke-TechIdApiRequest -ApiHost $ApiHost -Credential $Credential -Method POST -Endpoint $endpoint -Body $body -ShowApiCall:$ShowApiCall -CallingFunction "New-TechIdTech"

                Write-Verbose "Technician '$Name' created successfully."

                # Handle Group assignments if requested
                if ($TechGroups) {
                    Write-Verbose "Waiting 2 seconds for API consistency before adding groups..."
                    Start-Sleep -Seconds 2
                    
                    # We need to verify the tech exists and get its ID (though Add-TechIdTechToGroup uses name lookup)
                    $newTech = Get-TechIdTech -TechnicianName $Name -Credential $Credential -ApiHost $ApiHost
                    
                    if ($newTech) {
                        foreach ($groupName in $TechGroups) {
                            Write-Verbose "Adding '$Name' to group '$groupName'..."
                            Add-TechIdTechToGroup -TechnicianName $Name -GroupName $groupName -Credential $Credential -ApiHost $ApiHost -ShowApiCall:$ShowApiCall
                        }
                    }
                    else {
                        Write-Warning "Technician '$Name' was created but could not be retrieved immediately. Group assignments failed."
                    }
                }
            }
            catch {
                Write-Error "Failed to create technician '$Name': $($_.Exception.Message)"
            }
        }
    }
}
