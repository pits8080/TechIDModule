function Set-TechIdAgentLeaf {
    <#
.SYNOPSIS
    Assigns an agent record to a specific account leaf in TechID.
.DESCRIPTION
    This command updates an agent's 'AccountLeaf' property. Based on the API documentation, this is achieved
    by sending a POST request to a specific endpoint that includes both the Agent ID and the Leaf Path.
    If the specified leaf path does not exist, this command will first create it.
.PARAMETER AgentName
    The full, exact name of the agent to be modified (e.g., "SERVER01\AgentAdmin").
.PARAMETER DomainGuid
    The GUID of the agent to be modified. Use this to skip the name lookup.
.PARAMETER Leaf
    The full hierarchical path of the account leaf to assign (e.g., "MyCompany.Customer.Site").
.EXAMPLE
    PS C:\> Set-TechIdAgentLeaf -AgentName "SERVER01\Agent" -Leaf "MyCompany.Customer.Site" -WhatIf

    Description:
    Shows that it would assign the agent to the "MyCompany.Customer.Site" leaf. No actual changes are made.
.EXAMPLE
    PS C:\> Set-TechIdAgentLeaf -DomainGuid "36979b3e-295a-442d-9ced-c2ca06b0ff07" -Leaf "MyCompany.Customer.Site"

    Description:
    Assigns the agent with the specified GUID to the leaf "MyCompany.Customer.Site".
.NOTES
    Author:      Daniel Houle
    Date:        2025-12-30
    Version:     3.0.0

    VERSION HISTORY:
    2.1.0 - 2025-12-30 - Added support for -DomainGuid to target agents by ID directly.
    2.0.0 - 2025-09-30 - Complete rewrite to use the correct POST /client/agent/{AgentId}/accountleaf/{LeafPath} endpoint.
#>
    [CmdletBinding(DefaultParameterSetName = 'ByName', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ByName')]
        [Alias('Name')]
        [string]$AgentName,

        [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
        [string]$DomainGuid,

        [Parameter(Mandatory = $true)]
        [string]$Leaf,

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
            $agentId = $null
            $targetDescription = ""

            if ($PSCmdlet.ParameterSetName -eq 'ByName') {
                # Step 1: Find the agent to get its ID.
                Write-Verbose "Searching for agent record '$AgentName'..."
                $agentToUpdate = Get-TechIdAgents -AgentName $AgentName -Credential $Credential -ApiHost $ApiHost
                
                if (-not $agentToUpdate) {
                    throw "Agent with name '$AgentName' not found."
                }
                if ($agentToUpdate.Count -gt 1) {
                    throw "Multiple agents found matching '$AgentName'. For safety, this command requires a unique, exact name."
                }
                $agentId = $agentToUpdate.DomainId
                $targetDescription = "'$AgentName' (ID: $agentId)"
            }
            else {
                # Look up the agent by GUID to get the internal DomainId
                Write-Verbose "Searching for agent with DomainGuid '$DomainGuid'..."
                $agentToUpdate = Get-TechIdAgents -DomainGuid $DomainGuid -Credential $Credential -ApiHost $ApiHost

                if (-not $agentToUpdate) {
                    throw "Agent with DomainGuid '$DomainGuid' not found."
                }
                # Get-TechIdAgents filters by GUID, so we should get exactly one or none, but handle array just in case
                if ($agentToUpdate.Count -gt 1) {
                    # This implies duplicate GUIDs which shouldn't happen, but pick the first or throw?
                    # Let's verify uniqueness.
                    $agentToUpdate = $agentToUpdate | Select-Object -First 1
                }
                
                $agentId = $agentToUpdate.DomainId
                $name = $agentToUpdate.Name
                $targetDescription = "'$name' (ID: $agentId, GUID: $DomainGuid)"
            }
            
            # Step 2: Check if the target leaf exists and create if not.
            Write-Verbose "Checking for existence of leaf '$Leaf'..."
            $allLeafs = Get-TechIdLeaf -Credential $Credential -ApiHost $ApiHost
            $leafExists = $allLeafs | Where-Object { $_.Path -eq $Leaf }

            if (-not $leafExists) {
                Write-Warning "Leaf '$Leaf' does not exist. It will be created."
                New-TechIdLeaf -Path $Leaf -Credential $Credential -ApiHost $ApiHost
            }

            # Step 3: Construct the API request using the new, correct endpoint.
            $encodedLeafPath = [System.Uri]::EscapeDataString($Leaf)
            $endpoint = "/client/agent/$agentId/accountleaf/$encodedLeafPath"
            
            if ($PSCmdlet.ShouldProcess($targetDescription, "Set AccountLeaf to '$Leaf'")) {
                $apiRequest = @{
                    ApiHost         = $ApiHost
                    Credential      = $Credential
                    Endpoint        = $endpoint
                    Method          = 'POST'
                    ShowApiCall     = $ShowApiCall
                    CallingFunction = 'Set-TechIdAgentLeaf'
                }
                Invoke-TechIdApiRequest @apiRequest

                Write-Host "Successfully updated AccountLeaf for $targetDescription." -ForegroundColor Green
            }
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-Error "A fatal error occurred while trying to set AccountLeaf for ${targetDescription}: $errorMessage"
        }
    }
}

