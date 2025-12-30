function Set-TechIdCredential {
    <#
.SYNOPSIS
    Prompts for or directly sets the TechID API credentials and saves them to a local XML file.
.DESCRIPTION
    This function securely saves the TechID API credential object to an encrypted XML file in the user's profile.
    It can be run interactively to prompt for credentials, or non-interactively by providing the manager's email and API key as parameters.
.PARAMETER ManagerEmail
    The email address of the manager account associated with the API Key.
.PARAMETER ApiKey
    The API Key for the TechID service.
.PARAMETER Path
    The full path to the directory where the credential file will be stored.
    Defaults to '$HOME\TechID'.
.EXAMPLE
    PS C:\> Set-TechIdCredential

    Description:
    Prompts the user interactively for their credentials and saves them to C:\Users\<username>\TechID\TechID.cred.xml.
.EXAMPLE
    PS C:\> Set-TechIdCredential -ManagerEmail "admin@example.com" -ApiKey "YourSuperSecretApiKey"

    Description:
    Non-interactively creates and saves the credential file. This is ideal for use in automated scripts.
.NOTES
    Author:      Daniel Houle
    Date:        2025-09-03
    Version:     3.0.0

    VERSION HISTORY:
    1.1.0 - 2025-09-03 - Added non-interactive parameter set for automation.
    1.0.0 - 2025-09-03 - Initial function creation.
#>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ManagerEmail,

        [Parameter(Mandatory = $true)]
        [string]$ApiKey,

        [Parameter(Mandatory = $true)]
        [string]$ApiHost,

        [Parameter(Mandatory = $false)]
        [string]$Path = (Join-Path -Path $HOME -ChildPath 'TechID')
    )

    try {
        $cred = $null

        Write-Verbose "Creating credential object non-interactively."
        $secureApiKey = ConvertTo-SecureString -String $ApiKey -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential($ManagerEmail, $secureApiKey)

        if (-not $cred) {
            Write-Warning "Credential creation failed or was cancelled. No file was saved."
            return
        }

        if (-not (Test-Path -Path $Path)) {
            Write-Verbose "Creating directory: $Path"
            if ($PSCmdlet.ShouldProcess($Path, "Create Directory")) {
                New-Item -Path $Path -ItemType Directory -Force | Out-Null
            }
        }

        $filePath = Join-Path -Path $Path -ChildPath "TechID.cred.xml"
        
        if ($PSCmdlet.ShouldProcess($filePath, "Save Credential File")) {
            $cred | Export-CliXml -Path $filePath
            Write-Host "Credential file saved successfully to '$filePath'" -ForegroundColor Green
        }

        # Handle ApiHost configuration
        $configPath = Join-Path -Path $Path -ChildPath "TechID.config.json"
        $configData = @{ ApiHost = $ApiHost }
        if ($PSCmdlet.ShouldProcess($configPath, "Save API Host Configuration")) {
            $configData | ConvertTo-Json | Set-Content -Path $configPath
            # Update the session variable immediately
            $script:DefaultApiHost = $ApiHost
            Write-Host "API Host configuration saved to '$configPath' (Host: $ApiHost)" -ForegroundColor Green
        }
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Error "A fatal error occurred: $errorMessage"
    }
}
