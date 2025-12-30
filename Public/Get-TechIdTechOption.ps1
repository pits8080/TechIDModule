function Get-TechIdTechOption {
<#
.SYNOPSIS
    Retrieves the specific client options for a single technician.
.DESCRIPTION
    This command connects to the TechID API to get the detailed configuration options for a specific technician,
    such as 'AllowOneTimeShare' or 'IdleLockTime'. It requires an exact technician name.
.PARAMETER TechnicianName
    The full, exact name of the technician to retrieve options for. This parameter is mandatory and supports pipeline input.
.PARAMETER Credential
    A PSCredential object. If omitted, the function will look for a saved credential file.
.PARAMETER ApiHost
    The base URL for the TechID API endpoint. Defaults to the configured default host.
.PARAMETER ShowApiCall
    If specified, the function will display the raw API request details for its internal calls.
.EXAMPLE
    PS C:\> Get-TechIdTechOption -TechnicianName "dantest"

    Description:
    Retrieves the current client option settings for the technician named "dantest".
.EXAMPLE
    PS C:\> Get-TechIdTech -TechnicianName "dantest" | Get-TechIdTechOption

    Description:
    Finds the technician object for "dantest" and pipes it to this command to get their options.
.NOTES
    Author:      Daniel Houle
    Date:        2025-09-11
    Version:     3.0.0

    VERSION HISTORY:
    1.3.0 - 2025-09-12 - Added -ShowApiCall switch for debugging.
    1.2.0 - 2025-09-11 - Changed logic to parse existing TechOptions property instead of making a new API call.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Name')]
        [string]$TechnicianName,

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
        try {
            Write-Verbose "Finding technician '$TechnicianName'..."
            $technician = Get-TechIdTech -TechnicianName $TechnicianName -Credential $Credential -ApiHost $ApiHost -ShowApiCall:$PSBoundParameters['ShowApiCall']
            
            if (-not $technician) {
                throw "Technician with name '$TechnicianName' not found."
            }
            if ($technician.Count -gt 1) {
                throw "Multiple technicians found matching '$TechnicianName'. Please provide a unique name."
            }

            Write-Verbose "Parsing existing TechOptions property for '$TechnicianName'."
            $optionsMap = @{}
            foreach ($option in $technician.TechOptions) {
                $optionsMap[$option.Name] = $option.Value
            }
            
            $options = [PSCustomObject]@{
                TechnicianName          = $technician.Name
                AllowOneTimeShare       = $optionsMap['AllowOneTimeShare']
                AllowAccountCaching     = $optionsMap['AllowAccountCaching']
                AllowExportKeys         = $optionsMap['AllowExportKeys']
                IdleLockTimeInMinutes   = $optionsMap['IdleLockMinutes']
                MfaForTechIdClient      = $optionsMap['ForceMFA']
                ShowMobileTab           = $optionsMap['ShowMobileTab']
                ShowUserPasswordTab     = $optionsMap['UserPasswordTab']
                ShowVaultPasswordTab    = $optionsMap['VaultPasswordTab']
            }

            return $options
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-Error "A fatal error occurred while trying to get options for technician '$TechnicianName': $errorMessage"
        }
    }
}
