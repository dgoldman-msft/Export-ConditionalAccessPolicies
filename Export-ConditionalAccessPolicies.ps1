function Export-ConditionalAccessPolicies {

    <#
        .SYNOPSIS
            Export conditional access policies

        .DESCRIPTION
            Export Azure active directory conditional access policies

        .PARAMETER Endpoint
            Graph API version endpoint

        .PARAMETER ExportToJSON
            Switch to export data to a JSON file

        .PARAMETER ExportFolderName
            Logging folder

        .PARAMETER LoggingPath
            Logging Path

        .PARAMETER ShowModuleInfoInVerbose
            Show verbose information for module installation and loading

        .EXAMPLE
            C:\PS> Export-ConditionalAccessPolicies -ShowModuleInfoInVerbose

            Connect to an Azure tenant and retrieve all conditional access policies and display to the screen with full PowerShell module verbose information

        .EXAMPLE
            C:\PS> Export-ConditionalAccessPolicies

            Connect to an Azure tenant and retrieve all conditional access policies and display to the screen

        .EXAMPLE
            C:\PS> Export-ConditionalAccessPolicies -ExportToJSON

            Connect to an Azure tenant and retrieve all conditional access policies and display and export them to JSON format.

        .NOTES
            https://learn.microsoft.com/en-us/powershell/microsoftgraph/get-started?view=graph-powershell-1.0
            https://learn.microsoft.com/en-us/graph/api/resources/intune-shared-devicemanagement?view=graph-rest-beta
    #>

    [OutputType('PSCustomObject')]
    [CmdletBinding()]
    [Alias('ExportCA')]
    param(
        [ValidateSet('Global', 'GCC', 'DOD')]
        [parameter(Position = 0)]
        [string]
        $Endpoint = 'Global',

        [switch]
        $ExportToJSON,

        [string]
        $ExportFolderName = "ExportedConditionalAccessPolicies",

        [ValidateSet('Beta', 'v1.0')]
        [parameter(Position = 0)]
        $GraphVersion = "Beta",

        [parameter(Position = 2)]
        [string]
        $LoggingPath = "$env:Temp\$ExportFolderName",

        [switch]
        $ShowModuleInfoInVerbose
    )

    begin {
        Write-Output "Starting conditional access policy export"
        $parameters = $PSBoundParameters
        $modules = @("Microsoft.Graph.Authentication", "Microsoft.Graph.Intune")
        $script:successful = $false
    }

    process {
        if ($PSVersionTable.PSEdition -ne 'Core') {
            Write-Output "You need to run this script using PowerShell core due to dependencies."
            return
        }

        try {
            # Leaving this here in case the root directory gets deleted between executions so we will re-create it again
            if (-NOT(Test-Path -Path $LoggingPath)) {
                if (New-Item -Path $LoggingPath -ItemType Directory -ErrorAction Stop) {
                    Write-Verbose "$LoggingPath directory created!"
                }
                else {
                    Write-Verbose "$($LoggingPath) already exists!"
                }
            }
        }
        catch {
            Write-Output "Error: $_"
            return
        }

        try {
            foreach ($module in $modules) {
                if ($found = Get-Module -Name $module -ListAvailable | Sort-Object Version | Select-Object -First 1) {
                    if (Import-Module -Name $found -ErrorAction Stop -Verbose:$ShowModuleInfoInVerbose -PassThru) {
                        Write-Verbose "$found imported!"
                        $script:successful = $true
                    }
                    else {
                        Throw "Error importing $($found). Please Run Export-ConditionalAccessPolicies -Verbose -ShowModuleInfoInVerbose"
                    }
                }
                else {
                    Write-Output "$module not found! Installing module $($module) from the PowerShell Gallery"
                    if (Install-Module -Name $module -Repository PSGallery -Force -Verbose:$ShowModuleInfoInVerbose -PassThru) {
                        Write-Verbose "$module installed successfully! Importing $($module)"
                        if (Import-Module -Name $module -ErrorAction Stop -Verbose:$ShowModuleInfoInVerbose -PassThru) {
                            Write-Verbose "$module imported successfully!"
                            $script:successful = $true
                        }
                        else {
                            Throw "Error importing $($found). Please Run Export-ConditionalAccessPolicies -Verbose -ShowModuleInfoInVerbose"
                        }
                    }
                }
            }
        }
        catch {
            Write-Output "Error: $_"
            return
        }

        try {
            Connect-MgGraph -Scopes "Policy.Read.All"
            switch ($Endpoint) {
                'Global' {
                    $uri = "https://graph.microsoft.com/$GraphVersion/identity/conditionalAccess/policies"
                    continue
                }
                'GCC' {
                    $uri = "https://graph.microsoft.us/$GraphVersion/identity/conditionalAccess/policies"
                    continue
                }
                'DoD' {
                    $uri = "https://dod-graph.microsoft.us/$GraphVersion/identity/conditionalAccess/policies"
                    continue
                }
            }
        }
        catch {
            Write-Output "Error: $_"
            return
        }

        try {
            Write-Verbose "Querying Graph uri: $($uri) for policy settings"
            if ($caPolicies = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop) {
                foreach ($policy in $caPolicies.Value) {
                    if ($parameters.ContainsKey('ExportToJSON')) {
                        $policy | ConvertTo-Json -Depth 10 | Set-Content (Join-Path -Path $LoggingPath -ChildPath $($policy.displayName + ".json")) -ErrorAction Stop -Encoding UTF8
                    }
                }
            }
            else {
                Write-Output "No results returned!"
            }

            # Display to the console results
            $caPolicies.Value.displayName
        }
        catch {
            Write-Output "Error: $_"
            return
        }
    }

    end {
        if ($parameters.ContainsKey('ExportToJSON')) { Write-Output "`nResults exported to: $($LoggingPath)" }
        Write-Output "Completed!"
    }
}