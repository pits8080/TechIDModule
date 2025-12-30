function New-TechIdLeaf {
<#
.SYNOPSIS
    Creates a new account leaf in TechID.
.DESCRIPTION
    Connects to the TechID API to create a new hierarchical account leaf based on the provided path.
.PARAMETER Path
    The full hierarchical path for the new leaf (e.g., "Parent.Customer.Site"). This parameter is mandatory.
.PARAMETER Credential
    A PSCredential object. If omitted, the function will look for a saved credential file.
.PARAMETER ApiHost
    The base URL for the TechID API endpoint. Defaults to 'https://ch010.ruffiansoftware.com'.
.PARAMETER ShowApiCall
    If specified, the function will display the raw API request details before execution.
.EXAMPLE
    PS C:\> New-TechIdLeaf -Path "TNN.NewCustomer.MainOffice"

    Description:
    Creates a new leaf in TechID named "MainOffice" under "NewCustomer" and "TNN".
.EXAMPLE
    PS C:\> New-TechIdLeaf -Path "TNN.Customer.Site" -WhatIf

    Description:
    Shows what would happen if the command were run, without actually creating the leaf.
.NOTES
    Author:      Daniel Houle
    Date:        2025-09-30
    Version:     1.4.0
    
    VERSION HISTORY:
    1.4.0 - 2025-09-30 - Renamed from New-TechIDAgentLeaf for clarity.
#>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

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
        try {
            if ($PSCmdlet.ShouldProcess($Path, "Create TechID Leaf")) {
                $apiRequest = @{
                    ApiHost         = $ApiHost
                    Credential      = $Credential
                    Endpoint        = "/client/accountleaf/0"
                    Method          = 'POST'
                    Body            = @{ Path = $Path }
                    ShowApiCall     = $ShowApiCall
                    CallingFunction = 'New-TechIdLeaf'
                }
                $apiResult = Invoke-TechIdApiRequest @apiRequest

                Write-Host "Successfully created leaf '$Path'." -ForegroundColor Green
                return $apiResult
            }
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-Error "A fatal error occurred while creating leaf '$Path': $errorMessage"
        }
    }
}
