# TechIDManager Module for PowerShell

A comprehensive PowerShell module for managing [TechID Manager](https://techidmanager.com) resources via the TechID API. This module allows administrators to automate the management of technicians, agents (domains), groups, and organizational structures (leafs).

## Features

*   **Technician Management**: Create, retrieve, and manage technician accounts and group memberships.
*   **Agent Management**: Retrieve agent details, set options (JIT, rotation), and assign to organizational leafs.
*   **Group Management**: Manage Agent Groups, Technician Groups, and Rights Groups.
*   **Organization**: Create and manage Account Leafs to structure your resources.
*   **Triplets**: Manage TechID Triplets connecting Technicians, Agents, and Rights.
*   **Secure Authentication**: Securely store and use API credentials.

## Installation

### Manual Installation
1.  Download the `ModuleV2` folder.
2.  Rename the folder to `TechIDManagerModule` (matching the `.psd1` file name).
3.  Place the folder in one of your PowerShell module paths (e.g., `C:\Program Files\PowerShell\Modules` or `~\Documents\PowerShell\Modules`).
4.  Import the module:
    ```powershell
    Import-Module TechIDManagerModule
    ```

### Direct Import
You can also import the module directly from the source file without installing it to a module path:
```powershell
Import-Module "C:\Path\To\TechIDManagerModule\TechIDManagerModule.psd1"
```

## Configuration & Authentication

Before using any commands, you must configure your API credentials. You will need your Manager Email and an API Key (obtained from the TechID Manager portal).

### One-Time Setup
Run the following command to securely store your credentials. You only need to do this once; subsequent commands will automatically load these credentials.

**Interactive Mode (Secure):**
```powershell
Set-TechIdCredential
# A credential prompt will appear:
# Username: Your Manager Email
# Password: Your API Key
```

**Automated Mode:**
```powershell
Set-TechIdCredential -ManagerEmail "admin@example.com" -ApiKey "your-api-key-here"
```

## Quick Start Examples

### Manage Technicians
```powershell
# Get all technicians
Get-TechIdTech

# Create a new technician
New-TechIdTech -Name "jdoe" -FirstName "John" -LastName "Doe" -Email "jdoe@example.com"

# Add a technician to a group
Add-TechIdTechToGroup -TechnicianName "jdoe" -GroupName "Tier 1 Support"
```

### Manage Agents
```powershell
# Get all agents matching a pattern
Get-TechIdAgents -AgentName "SERVER-*"

# Enable Just-In-Time (JIT) access for an agent
Get-TechIdAgents -AgentName "SERVER-01\Admin" | Set-TechIdAgentOptions -JustInTime "1"

# Move an agent to a specific organized leaf
Set-TechIdAgentLeaf -Leaf "Client.Site.Servers" -AgentName "SERVER-01\Admin"
```

### Manage Groups
```powershell
# Get all agent groups
Get-TechIdAgentGroups

# Add multiple agents to a group using the pipeline
Get-TechIdAgents -AgentName "WEB-*" | Add-TechIdAgentToGroup -GroupName "Web Servers"
```

## Available Functions

### Technicians
*   `New-TechIdTech`
*   `Get-TechIdTech`
*   `Get-TechIdTechOption`
*   `Set-TechIdTechOption`
*   `Add-TechIdTechToGroup`
*   `Remove-TechIdTechFromGroup`
*   `Get-TechIdTechMembership`
*   `Get-TechIdTechGroups`
*   `Remove-TechIdTechGroup`

### Agents (Domains)
*   `Get-TechIdAgents`
*   `Set-TechIdAgentOptions`
*   `Remove-TechIdAgent`
*   `Get-TechIdAgentGroups`
*   `Add-TechIdAgentToGroup`
*   `Remove-TechIdAgentFromGroup`
*   `Get-TechIdAgentMembership`
*   `Remove-TechIdAgentGroup`

### Organization (Leafs)
*   `Get-TechIdLeaf`
*   `New-TechIdLeaf`
*   `Remove-TechIdLeaf`
*   `Set-TechIdAgentLeaf`

### Triplets & Access
*   `New-TechIDTriplet`
*   `Get-TechIDTriplet`
*   `Remove-TechIDTriplet`
*   `Set-TechIDTripletOption`
*   `Get-TechIDRightsGroup`

### Utilities
*   `Set-TechIdCredential`
*   `Get-TechIdAPIKeys`

## Contributing
Contributions are welcome! Please submit a pull request or open an issue to suggest improvements.

## License
This project is open and available for use.




Now you can buy me a coffee! 

<h3 align="left">Support:</h3>
<p><a href="https://buymeacoffee.com/dhoule"> <img align="left" src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" height="50" width="210" alt="https://buymeacoffee.com/dhoule" /></a></p><br><br>
