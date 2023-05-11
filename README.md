# Export-ConditionalAccessPolicies
Export Azure Conditional Access Policies via GraphAPI

## Getting Started with Export-ConditionalAccessPolicies

You must be running PowerShell 7 for this script to work due to dependencies.

Running this script you agree to install Microsoft.Graph PowerShell modules and consent to permissions on your system so you can connect to GraphAPI to export Intune policy information

### DESCRIPTION

Connect using Graph API (Beta) and export Conditional Access Policies.

### Examples

- EXAMPLE 1: C:\PS> Export-ConditionalAccessPolicies

    Connect to an Azure tenant and retrieve all conditional access policies and display to the screen

- EXAMPLE 2: C:\PS> Export-ConditionalAccessPolicies -ShowModuleInfoInVerbose

    Connect to an Azure tenant and retrieve all conditional access policies and display to the screen with full PowerShell module verbose information

- EXAMPLE 3: C:\PS> Export-ConditionalAccessPolicies -ExportToJSON

    Connect to an Azure tenant and retrieve all conditional access policies and display and export them to JSON format.

### Note on file export

All policies will be exported in csv or json to "$env:Temp\ExportedConditionalAccessPolicies". This path can be changed if necessary.