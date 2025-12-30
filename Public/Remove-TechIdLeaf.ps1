function Remove-TechIdLeaf {
    <#
.SYNOPSIS
    Removes an account leaf from TechID.
.DESCRIPTION
    Connects to the TechID API to remove a specific account leaf.
.PARAMETER LeafId
    The ID of the leaf to remove.
.PARAMETER Credential
    A PSCredential object. If omitted, the function will look for a saved credential file.
.PARAMETER ApiHost
    The base URL for the TechID API endpoint. Defaults to 'https://ch010.ruffiansoftware.com'.
.PARAMETER ShowApiCall
    If specified, the function will display the raw API request details before execution.
.EXAMPLE
    PS C:\> Remove-TechIdLeaf -LeafId 123
    
    Description:
    Removes the leaf with ID 123.
.EXAMPLE
    PS C:\> Get-TechIdLeaf | Where-Object { $_.Name -eq 'OldLeaf' } | Remove-TechIdLeaf
    
    Description:
    Finds the leaf named 'OldLeaf' and removes it.
.NOTES
    Author:      Daniel Houle
    Date:        2025-11-25
    Version:     1.0.0
#>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ById')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'ById', ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Id', 'AccountLeafId')]
        [int]$LeafId,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByPath')]
        [Alias('Name')]
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
            $idsToRemove = @()

            if ($PSCmdlet.ParameterSetName -eq 'ByPath') {
                Write-Verbose "Resolving leaf path '$Path'..."
                $leaves = Get-TechIdLeaf -Path $Path -Credential $Credential -ApiHost $ApiHost
                
                if (-not $leaves) {
                    Write-Warning "No leaves found matching path '$Path'."
                    return
                }

                foreach ($leaf in $leaves) {
                    $idsToRemove += @{ Id = $leaf.AccountLeafId; Name = $leaf.Path }
                }
            }
            else {
                $idsToRemove += @{ Id = $LeafId; Name = "ID: $LeafId" }
            }

            foreach ($item in $idsToRemove) {
                $targetId = $item.Id
                $targetName = $item.Name

                if ($PSCmdlet.ShouldProcess("Leaf: $targetName ($targetId)", "Remove TechID Leaf")) {
                    $apiRequest = @{
                        ApiHost         = $ApiHost
                        Credential      = $Credential
                        Endpoint        = "/client/accountleaf/$targetId"
                        Method          = 'DELETE'
                        ShowApiCall     = $ShowApiCall
                        CallingFunction = 'Remove-TechIdLeaf'
                    }
                    $apiResult = Invoke-TechIdApiRequest @apiRequest

                    Write-Host "Successfully removed leaf '$targetName' (ID: $targetId)." -ForegroundColor Green
                }
            }
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-Error "A fatal error occurred: $errorMessage"
        }
    }
}
