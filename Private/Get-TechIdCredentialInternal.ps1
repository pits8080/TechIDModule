function Get-TechIdCredentialInternal {
    <#
.SYNOPSIS
    Internal helper to resolve and return the TechID credential.
.DESCRIPTION
    Centralizes the logic for obtaining the PSCredential object. If a credential is provided
    directly, it is used. Otherwise, it attempts to load the credential from the standard
    XML file path. Throws an error if no credential can be found.
.PARAMETER Credential
    An existing PSCredential object.
.OUTPUTS
    [System.Management.Automation.PSCredential] The resolved credential object.
#>
    param (
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]$Credential
    )

    if ($PSBoundParameters.ContainsKey('Credential') -and $Credential) {
        return $Credential
    }

    $credFilePath = Join-Path -Path $HOME -ChildPath 'TechID/TechID.cred.xml'
    if (Test-Path -Path $credFilePath) {
        return Import-Clixml -Path $credFilePath
    }
    else {
        throw "No credential was provided, and a saved credential file was not found at '$credFilePath'. Please run Set-TechIdCredential first to configure your credentials."
    }
}
