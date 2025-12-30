function Get-TechIdAgentOptions {
<#
.SYNOPSIS
    Retrieves all specific client options for a single agent.
.DESCRIPTION
    This command connects to the TechID API to get the detailed configuration options for a specific agent by
    making a dedicated call to the /client/domain/info endpoint. It dynamically returns all options provided by the API.
.PARAMETER AgentName
    The full, exact name of the agent to retrieve options for.
.PARAMETER DomainGuid
    The Domain GUID of the agent to retrieve options for.
.PARAMETER InputObject
    An agent object piped from Get-TechIdAgents.
.NOTES
    Author:      Daniel Houle
    Date:        2025-10-09
    Version:     2.3.0

    VERSION HISTORY:
    2.3.0 - 2025-10-09 - Added InputObject parameter set to correctly handle pipeline input.
    2.2.0 - 2025-10-09 - Added DomainGuid parameter set.
    2.1.0 - 2025-10-08 - Refactored to dynamically display all options returned by the API.
    2.0.0 - 2025-10-08 - Complete rewrite to use the correct GET /client/domain/info endpoint.
#>
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param(
        [Parameter(ParameterSetName = 'ByInputObject', Mandatory = $true, ValueFromPipeline = $true)]
        [psobject]$InputObject,

        [Parameter(ParameterSetName = 'ByName', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Name')]
        [string]$AgentName,

        [Parameter(ParameterSetName = 'ByGuid', Mandatory = $true)]
        [string]$DomainGuid,

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
            $agent = $null
            $identifyingParam = $null

            switch ($PSCmdlet.ParameterSetName) {
                'ByInputObject' {
                    $agent = $InputObject
                    $identifyingParam = $agent.Name
                }
                'ByName' {
                    Write-Verbose "Finding agent '$AgentName' to get its ID..."
                    $agent = Get-TechIdAgents -AgentName $AgentName -Credential $Credential -ApiHost $ApiHost
                    if (-not $agent) { throw "Agent with name '$AgentName' not found." }
                    if ($agent.Count -gt 1) { throw "Multiple agents found matching '$AgentName'. Please provide a unique name or use -DomainGuid." }
                    $identifyingParam = $AgentName
                }
                'ByGuid' {
                    Write-Verbose "Finding agent with GUID '$DomainGuid'..."
                    $agent = Get-TechIdAgents -DomainGuid $DomainGuid -Credential $Credential -ApiHost $ApiHost
                    if (-not $agent) { throw "Agent with DomainGuid '$DomainGuid' not found." }
                    $identifyingParam = $DomainGuid
                }
            }
            
            $agentId = $agent.DomainId
            $resolvedAgentName = $agent.Name
            Write-Verbose "Found agent '$resolvedAgentName' with ID: $agentId"

            # Step 2: Make a dedicated API call to the /info endpoint to get the details.
            $apiRequest = @{
                ApiHost               = $ApiHost
                Credential            = $Credential
                Endpoint              = "/client/domain/info"
                Method                = 'GET'
                AdditionalQueryParams = @{ DomainID = $agentId }
                ShowApiCall           = $ShowApiCall
                CallingFunction       = 'Get-TechIdAgentOptions'
            }
            $agentDetails = Invoke-TechIdApiRequest @apiRequest
            
            # Step 3: Dynamically parse the results into a clean object.
            $optionsObject = [pscustomobject]@{
                AgentName  = $agentDetails.Name
                DomainGuid = $agent.DomainGuid
            }
            
            if ($agentDetails.DomainOptions) {
                foreach ($option in $agentDetails.DomainOptions) {
                    Add-Member -InputObject $optionsObject -MemberType NoteProperty -Name $option.Name -Value $option.Value
                }
            }

            return $optionsObject
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-Error "A fatal error occurred while trying to get options for agent '$identifyingParam': $errorMessage"
        }
    }
}
