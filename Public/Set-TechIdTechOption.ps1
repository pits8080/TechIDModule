function Set-TechIdTechOption {
<#
.SYNOPSIS
    Modifies the client options for a single technician.
.DESCRIPTION
    This command updates one or more client configuration options for a specific technician in TechID.
    It makes a separate, specific API call for each option that is being changed.
    It fully supports -WhatIf and -Confirm to allow for safe testing of changes.
.PARAMETER TechnicianName
    The full, exact name of the technician whose options you want to modify. This parameter is mandatory and supports pipeline input.
.PARAMETER AllowOneTimeShare
    Sets the 'Allow One Time Share' option. Valid values are 'unset', 'Yes', 'No'.
.PARAMETER AllowAccountCaching
    Sets the 'Allow Account Caching' option. Valid values are 'unset', 'Yes', 'No'.
.PARAMETER AllowExportKeys
    Sets the 'Allow Export Keys' option. Valid values are 'unset', 'Yes', 'No'.
.PARAMETER IdleLockTimeInMinutes
    Sets the idle lock time in minutes. Valid values are integers from 1 to 9999.
.PARAMETER MfaForTechIdClient
    Sets the MFA requirement for the TechID Client. Valid values are 'unset', 'Force', 'Suggest', 'Allow'.
.PARAMETER ShowMobileTab
    Sets the 'Show Mobile Tab' option. Valid values are 'unset', 'Yes', 'No'.
.PARAMETER ShowUserPasswordTab
    Sets the 'Show User Password Tab' option. Valid values are 'unset', 'Yes', 'No'.
.PARAMETER ShowVaultPasswordTab
    Sets the 'Show Vault Password Tab' option. Valid values are 'unset', 'Yes', 'No'.
.PARAMETER Credential
    A PSCredential object. If omitted, the function will look for a saved credential file.
.PARAMETER ApiHost
    The base URL for the TechID API endpoint. Defaults to the configured default host.
.PARAMETER ShowApiCall
    If specified, the function will display the raw API request details before execution.
.EXAMPLE
    PS C:\> Set-TechIdTechOption -TechnicianName "dantest" -AllowOneTimeShare "Yes" -IdleLockTimeInMinutes 60 -WhatIf

    Description:
    Shows what would happen if you enabled 'AllowOneTimeShare' and set the idle lock time to 60 minutes for the technician "dantest". No changes are actually made.
.EXAMPLE
    PS C:\> Get-TechIdTech -TechnicianName "dantest" | Set-TechIdTechOption -ShowMobileTab "No"

    Description:
    Finds the technician "dantest" and sets the 'ShowMobileTab' option to "No".
.NOTES
    Author:      Daniel Houle
    Date:        2025-09-12
    Version:     3.0.0

    VERSION HISTORY:
    2.1.0 - 2025-09-12 - Added -ShowApiCall switch for debugging.
    2.0.0 - 2025-09-12 - Complete rewrite based on developer feedback. Now uses POST /client/tech/option.
#>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Name')]
        [string]$TechnicianName,

        [Parameter(Mandatory = $false)]
        [ValidateSet('unset', 'Yes', 'No')]
        [string]$AllowOneTimeShare,

        [Parameter(Mandatory = $false)]
        [ValidateSet('unset', 'Yes', 'No')]
        [string]$AllowAccountCaching,

        [Parameter(Mandatory = $false)]
        [ValidateSet('unset', 'Yes', 'No')]
        [string]$AllowExportKeys,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 9999)]
        [int]$IdleLockTimeInMinutes,

        [Parameter(Mandatory = $false)]
        [ValidateSet('unset', 'Force', 'Suggest', 'Allow')]
        [string]$MfaForTechIdClient,

        [Parameter(Mandatory = $false)]
        [ValidateSet('unset', 'Yes', 'No')]
        [string]$ShowMobileTab,

        [Parameter(Mandatory = $false)]
        [ValidateSet('unset', 'Yes', 'No')]
        [string]$ShowUserPasswordTab,

        [Parameter(Mandatory = $false)]
        [ValidateSet('unset', 'Yes', 'No')]
        [string]$ShowVaultPasswordTab,

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

        # This mapping is crucial. It translates the PowerShell parameter name to the exact API property name.
        $script:paramToApiMap = @{
            AllowOneTimeShare       = 'AllowOneTimeShare'
            AllowAccountCaching     = 'AllowAccountCaching'
            AllowExportKeys         = 'AllowExportKeys'
            IdleLockTimeInMinutes   = 'IdleLockMinutes'
            MfaForTechIdClient      = 'ForceMFA'
            ShowMobileTab           = 'ShowMobileTab'
            ShowUserPasswordTab     = 'UserPasswordTab'
            ShowVaultPasswordTab    = 'VaultPasswordTab'
        }
    }

    process {
        try {
            Write-Verbose "Finding technician '$TechnicianName' to get their ID..."
            $technician = Get-TechIdTech -TechnicianName $TechnicianName -Credential $Credential -ApiHost $ApiHost -ShowApiCall:$false
            
            if (-not $technician) {
                throw "Technician with name '$TechnicianName' not found."
            }
            if ($technician.Count -gt 1) {
                throw "Multiple technicians found matching '$TechnicianName'. Please provide a unique name."
            }

            $techId = $technician.TechId
            Write-Verbose "Found technician with ID: $techId"

            # Loop through all the parameters that the user actually provided
            foreach ($paramName in $PSBoundParameters.Keys) {
                # We only care about the parameters that are in our mapping table
                if ($script:paramToApiMap.ContainsKey($paramName)) {
                    $apiPropertyName = $script:paramToApiMap[$paramName]
                    $apiPropertyValue = $PSBoundParameters[$paramName].ToString()
                    
                    if ($PSCmdlet.ShouldProcess("Technician '$TechnicianName'", "Set option '$apiPropertyName' to '$apiPropertyValue'")) {
                        $apiRequest = @{
                            ApiHost               = $ApiHost
                            Credential            = $Credential
                            Endpoint              = "/client/tech/option"
                            Method                = 'POST'
                            Body                  = @{ Name = $apiPropertyName; Value = $apiPropertyValue }
                            AdditionalQueryParams = @{ TechID = $techId }
                            ShowApiCall           = $ShowApiCall
                            CallingFunction       = 'Set-TechIdTechOption'
                        }
                        Invoke-TechIdApiRequest @apiRequest

                        Write-Host "Successfully set '$apiPropertyName' for technician '$TechnicianName'." -ForegroundColor Green
                    }
                }
            }
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-Error "A fatal error occurred while trying to set options for technician '$TechnicianName': $errorMessage"
        }
    }
}
