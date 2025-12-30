function Get-TechIdTech {
    <#
.SYNOPSIS
    Retrieves technician information from the TechID API.
.DESCRIPTION
    This function connects to the TechID API to retrieve a list of all technicians or a specific technician if a name is provided.
    If a credential is not provided, it will automatically attempt to load one from the path specified by Set-TechIdCredential.
.PARAMETER TechnicianName
    The name of a specific technician to retrieve. If omitted, the function returns all technicians. This parameter has an alias of 'Name' and supports wildcards.
.PARAMETER Credential
    A PSCredential object. The username should be the manager's email and the password should be the TechID API Key.
    If omitted, the function will look for a saved credential file at '$env:USERPROFILE\TechID\TechID.cred.xml'.
.PARAMETER ApiHost
    The base URL for the TechID API endpoint. Defaults to 'https://ch010.ruffiansoftware.com'.
.PARAMETER LogPath
    Path to the log file. If provided, verbose output will be written to this file.
.PARAMETER DryRun
    If specified, the function will log the actions it would take without actually making any API calls.
.PARAMETER ShowApiCall
    If specified, the function will display the raw API request details before execution.
.EXAMPLE
    PS C:\> Get-TechIdTech

    Description:
    Automatically loads the saved credential from the user's profile and retrieves all technicians.
.EXAMPLE
    PS C:\> Get-TechIdTech -TechnicianName "dant*"

    Description:
    Retrieves all technicians whose name starts with "dant" using a wildcard.
.EXAMPLE
    PS C:\> Get-TechIdTech -Verbose -LogPath "C:\Temp\TechID.log"

    Description:
    Retrieves all technicians, displays verbose output on the screen, and writes a detailed log to "C:\Temp\TechID.log".
.NOTES
    Author:      Daniel Houle
    Date:        2025-09-03
    Version:     1.6.0

    VERSION HISTORY:
    1.6.0 - 2025-09-20 - Refactored to use internal helper functions for credentials and API calls.
#>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false)]
        [Alias('Name')]
        [string]$TechnicianName,
        
        [Parameter(Mandatory = $false, HelpMessage = "Enter a credential object. Username = manager email, Password = API Key.")]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(Mandatory = $false)]
        [string]$ApiHost = "https://ch010.ruffiansoftware.com",

        [Parameter(Mandatory = $false)]
        [string]$LogPath,

        [Parameter(Mandatory = $false)]
        [switch]$DryRun,

        [Parameter(Mandatory = $false)]
        [switch]$ShowApiCall
    )

    begin {
        $Credential = Get-TechIdCredentialInternal -Credential $Credential

        # --- VERBOSE/LOGGING SETUP ---
        $scriptVersion = "1.6.0"
        $startMessage = "--- Get-TechIdTech Execution Started (Version: $scriptVersion) ---"
        Write-Verbose $startMessage
        if ($PSBoundParameters.ContainsKey('LogPath')) {
            Add-Content -Path $LogPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $startMessage" -Encoding UTF8
        }
    }

    process {
        try {
            # --- PARAMETER VERBOSE/LOGGING ---
            $paramMessage = @"
Parameters:
  Credential User: $($Credential.UserName)
  TechnicianName: $(if ([string]::IsNullOrEmpty($TechnicianName)) { '(All Technicians)' } else { $TechnicianName })
  ApiHost: $ApiHost
  LogPath: $(if ($PSBoundParameters.ContainsKey('LogPath')) { $LogPath } else { '(Not Specified)' })
  DryRun: $DryRun
"@
            Write-Verbose $paramMessage
            if ($PSBoundParameters.ContainsKey('LogPath')) {
                Add-Content -Path $LogPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $paramMessage" -Encoding UTF8
            }

            # The API for GET /client/techs normally uses a GET with a body, but PowerShell 5.1 does not support this.
            # We rely on Invoke-TechIdApiRequest to send the credentials (Email, authenticationmethod) in the Query String instead.
            
            if ($PSCmdlet.ShouldProcess("$ApiHost/client/techs", "Query TechID API for Technicians")) {
                $apiRequest = @{
                    ApiHost         = $ApiHost
                    Credential      = $Credential
                    Endpoint        = "/client/techs"
                    Method          = 'GET'
                    ShowApiCall     = $ShowApiCall
                    CallingFunction = 'Get-TechIdTech'
                }
                
                if ($DryRun) {
                    # Invoke-TechIdApiRequest doesn't natively handle DryRun in the same way as the original function
                    # so we simulate it here or pass it if we added support. 
                    # The original function returned early on DryRun.
                    # We can just use the ShowApiCall logic in the helper and return if DryRun is set.
                    # But wait, the helper doesn't know about DryRun.
                    # Let's manually handle DryRun here before calling the helper.
                    
                    $fullUrl = "$ApiHost/client/techs" # Approximate for logging
                    $dryRunMessage = "[DRYRUN] Would connect to URI: $fullUrl with Body: $($bodyParams | ConvertTo-Json -Compress)"
                    Write-Verbose $dryRunMessage
                    if ($PSBoundParameters.ContainsKey('LogPath')) {
                        Add-Content -Path $LogPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $dryRunMessage" -Encoding UTF8
                    }
                    Write-Warning "[DRYRUN] No API call will be made."
                    return
                }

                $apiResult = Invoke-TechIdApiRequest @apiRequest

                if (-not [string]::IsNullOrEmpty($TechnicianName)) {
                    $filterMessage = "Filtering results for technicians matching pattern: $TechnicianName"
                    Write-Verbose $filterMessage
                    if ($PSBoundParameters.ContainsKey('LogPath')) {
                        Add-Content -Path $LogPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $filterMessage" -Encoding UTF8
                    }
                    $apiResult = $apiResult | Where-Object { $_.Name -like $TechnicianName }
                }
                return $apiResult
            }
        }
        catch {
            $errorMessage = "FATAL ERROR: $($_.Exception.Message)"
            Write-Verbose $errorMessage
            if ($PSBoundParameters.ContainsKey('LogPath')) {
                Add-Content -Path $LogPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $errorMessage" -Encoding UTF8
                Write-Error "A fatal error occurred. Check the log for details: $LogPath"
            }
            else {
                Write-Error "A fatal error occurred: $($_.Exception.Message)"
            }
        }
    }

    end {
        $endMessage = "--- Get-TechIdTech Execution Finished ---`n"
        Write-Verbose $endMessage
        if ($PSBoundParameters.ContainsKey('LogPath')) {
            Add-Content -Path $LogPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $endMessage" -Encoding UTF8
        }
    }
}
