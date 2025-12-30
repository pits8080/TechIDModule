# Get the directory where this .psm1 file is located
$PSScriptRoot = $PSCommandPath | Split-Path

# Initialize Default API Host
# 1. Try to load from user config
# 2. Fallback to default if not found
$configPath = Join-Path -Path $env:USERPROFILE -ChildPath 'TechID\TechID.config.json'
if (Test-Path -Path $configPath) {
    try {
        $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
        $script:DefaultApiHost = $config.ApiHost
    }
    catch {
        Write-Warning "Failed to load TechID configuration from '$configPath'. Using default host."
    }
}

if ([string]::IsNullOrEmpty($script:DefaultApiHost)) {
    $script:DefaultApiHost = "https://ch010.ruffiansoftware.com"
}

# Dot-source all private helper functions first
# This makes them available to all the public functions
Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -Recurse | ForEach-Object {
    . $_.FullName
}

# Dot-source all public functions
Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -Recurse | ForEach-Object {
    . $_.FullName
}
