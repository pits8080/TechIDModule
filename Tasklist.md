TechIdManager PowerShell Module - Task List
This document tracks the development progress, pending issues, and future enhancements for the `TechIdManager` module.

✅ Completed Tasks
[x] Core Module Structure & Credential Management

[x] Created module files, logging, and Set-TechIdCredential function.

[x] Full "Read" Functionality (Get Commands)

[x] Get-TechIdTechnician (with wildcard support)

[x] Get-TechIdAgents (with wildcard support)

[x] Get-TechIDAgentLeaf (previously Get-TechIDallAgentLeaf)

[x] Get-TechIdTechnicianGroups (with member details)

[x] Get-TechIdAgentGroups (with member details)

[x] Get-TechIdTechnicianOption

[x] Get-TechIdAgentMembership (with performance caching, inverted to -NoCache)

[x] Get-TechIdTechnicianMembership (with performance caching, inverted to -NoCache)

[x] Core "Write" Functionality (New, Set, Remove)

[x] New-TechIDAgentLeaf

[x] New-TechIdTech

[x] Set-TechIdTechnicianOption (Core logic fixed per developer feedback)

[x] Remove-TechIdAgent (Fixed to use correct DELETE endpoint)

[x] Set-TechIdAgentLeaf (Assigns an agent to an account leaf)
    - [x] Added support for `-DomainGuid` to target agents by ID directly, bypassing name lookup.

[x] Add-TechIdAgentToGroup (Refactored to use correct POST endpoint)

[x] Remove-TechIdAgentFromGroup (Refactored to use correct DELETE endpoint)

[x] Technician Group Membership Management
    - [x] `Add-TechIdTechnicianToGroup` -> `Add-TechIdTechToGroup`
    - [x] `Remove-TechIdTechnicianFromGroup`

[x] Usability & Consistency

[x] Normalized parameters and added aliases (e.g., -TechnicianName, -Name).

[x] Implemented full pipeline support for command chaining.

[x] Added -WhatIf and -ShowApiCall support to all relevant functions.
[x] Added `SupportsShouldProcess` to functions that make changes.
[x] Standardized comment-based help and inline documentation tone.

[x] Security: Enforced exact match for `Remove-TechIdAgent`.

[x] **Security: Redact Secrets in Debug Output**
    - [x] Update the `-ShowApiCall` logic to mask the API key in the Authorization header (e.g., `Authorization: APIKey ****`).

[x] **Code Quality & Refactoring**
    - [x] Create private helper functions to reduce repeated code (DRY principle), especially for credential handling and API call construction.
    - [x] Improve logging to use `Write-Verbose` for verbose output and make the log path configurable in `Get-TechIdTechnician`.
    - [x] Aligned `New-TechIDAgentLeaf` request body with API documentation.

[x] **Create a module manifest (`.psd1`) file for proper module packaging and distribution.**

🛠️ Immediate Next Steps (High Priority)
[x] **Implement Triplet Functions**
    - [x] `Get-TechIDTriplet`
    - [x] `Get-TechIDRightsGroup`
    - [x] `New-TechIDTriplet`
    - [x] `Set-TechIDTripletOption`

[ ] **Comprehensive Testing & Validation**
    - [ ] **Action Item:** The vendor has provided the correct internal API names for technician options. The `Set-TechIdTechOption` and `Get-TechIdTechOption` functions have been updated to use this new mapping. All parameters should be re-tested to confirm the fix.
    - [ ] Systematically test every parameter for `Set-TechIdTechOption`:
        - [ ] Test `UserPasswordTab`
        - [ ] Test `VaultPasswordTab`
        - [x] Test `ShowMobileTab` - **SUCCESS**: API call works.
        - [x] Test `AllowExportKeys` - **SUCCESS**: API call works.
        - [x] Test `AllowOneTimeShare` - **SUCCESS**: API call works.
        - [ ] Test `ForceMFA`
        - [ ] Test `IdleLockMinutes`
        - [x] Test `AllowAccountCaching` - **SUCCESS**: API call works.
    - [ ] Validate both direct and pipeline usage for all functions to ensure consistent behavior.

[x] **API Consistency: Use Query Strings for all GET Requests**
    - [x] Refactor all `Get-*` commands to send authentication parameters in the URL's query string instead of the request body. This is already done for `POST`/`PUT` requests but not `GET` requests.

[ ] **Input Validation: Add `[ValidateNotNullOrEmpty()]`**
    - [ ] Add this attribute to all mandatory string parameters to provide clearer errors if a user provides an empty value.

[x] **Investigate `Set-TechIdAgentLeaf` behavior on agents with no assigned leaf.**
    - **Resolution:** The function was completely rewritten to use the correct `POST /client/agent/{AgentId}/accountleaf/{LeafPath}` endpoint, which resolved the underlying 404 error and confirmed the correct behavior.

📋 Future Enhancements (Roadmap)
[ ] Create a new function `Remove-TechIDAgentLeaf`
- [x] **Refactor Module Function Names**
  - **Goal:** Improve clarity and consistency of function names.
  - **Pattern:** Shorten `Technician` to `Tech` and standardize other names.
  - **Files to Modify:**
    - `TechIdManager.psm1` (definitions, internal calls, documentation)
    - `TechIdManager.psd1` (exported functions list)
  - **New Test Script:**
    - Create `Test-ModuleFunctions.ps1` with placeholder variables and safe, commented-out test cases for the new functions.
  - **"Tech" Rename Details:**
    - [x] `Add-TechIdTechnicianToGroup` -> `Add-TechIdTechToGroup`
    - [x] `Get-TechIdTechnician` -> `Get-TechIdTech`
    - [x] `Get-TechIdTechnicianGroups` -> `Get-TechIdTechGroups`
    - [x] `Get-TechIdTechnicianMembership` -> `Get-TechIdTechMembership`
    - [x] `Get-TechIdTechnicianOption` -> `Get-TechIdTechOption`
    - [x] `Remove-TechIdTechnicianFromGroup` -> `Remove-TechIdTechFromGroup`
    - [x] `Remove-TechIdTechnicianGroup` -> `Remove-TechIdTechGroup`
    - [x] `Set-TechIdTechnicianOption` -> `Set-TechIdTechOption`
  - **"Agent" Rename Details:**
    - `Get-TechIdAgentMembership` -> `Get-TechIdAgentGroupMembership`
    - [x] `Get-TechIDallAgentLeaf` -> `Get-TechIDAgentLeaf`
    - `New-TechIDAgentLeaf` -> `New-TechIdAgentLeaf` (casing)

## 📚 Swagger API Coverage

This section tracks the development of modules identified from the Swagger documentation and shows what is already implemented.

### **Account Management** (`/client/account`)
- [ ] `Get-TechIdAccount` (Management Console Users)
- [ ] `New-TechIdAccount`
- [ ] `Remove-TechIdAccount`
- [x] `Get-TechIdApiKey` (Implemented as `Get-TechIdAPIKeys`)
- [ ] `New-TechIdApiKey`
- [ ] `Remove-TechIdApiKey`

### **Account Leaf Management** (`/client/accountleaf`)
- [x] `Get-TechIdAccountLeaf` (Implemented as `Get-TechIdLeaf`)
- [x] `New-TechIdAccountLeaf` (Implemented as `New-TechIdLeaf`)
- [x] `Remove-TechIdAccountLeaf` (Implemented as `Remove-TechIdLeaf`)
- [x] `Set-TechIdAgentLeaf` (Assign Agent to Leaf)

### **Agent (Domain) Management** (`/client/domain`, `/client/agent`)
- [x] `Get-TechIdAgents` (List Agents)
- [x] `Remove-TechIdAgent` (Remove Agent)
- [x] `Set-TechIdAgentOptions` (Set Agent Options)
- [ ] `Get-TechIdDomainAzureBase`
- [ ] `Set-TechIdDomainAzureBase`
- [ ] `Get-TechIdDomainAzurePrimary`
- [ ] `Set-TechIdDomainAzurePrimary`
- [ ] `Get-TechIdDomainLink`
- [ ] `Remove-TechIdDomainLink`

### **Technician Management** (`/client/techs`)
- [x] `Get-TechIdTech` (List Technicians)
- [x] `New-TechIdTech` (Create Technician)
- [x] `Set-TechIdTechOption` (Set Tech Options)

### **Group Management** (`/client/techgroup`, `/client/agentgroup`)
- [x] `Get-TechIdTechGroups`
- [x] `Add-TechIdTechToGroup`
- [x] `Remove-TechIdTechFromGroup`
- [x] `Remove-TechIdTechGroup`
- [x] `Get-TechIdAgentGroups`
- [x] `Add-TechIdAgentToGroup`
- [x] `Remove-TechIdAgentFromGroup`
- [x] `Remove-TechIdAgentGroup`

### **Report Management** (`/client/report`)
- [ ] `Get-TechIdReportSchedule`
- [ ] `Set-TechIdReportSchedule`
- [ ] `Remove-TechIdReportSchedule`
- [ ] `Invoke-TechIdReportTrigger`
- [ ] `Get-TechIdReportNoContact`
- [ ] `Get-TechIdReportDomainNoContact`

### **Tech Vault Management** (`/tech/vault`)
- [ ] `Get-TechIdVaultPasswords`
- [ ] `Set-TechIdVaultTech`
- [ ] `Set-TechIdVaultPasswordUsed`