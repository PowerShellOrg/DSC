function Invoke-DscBuild
{
    <#
        .Synopsis
            Starts a build of DSC configurations, resources, and tools.
        .Description
            Starts a build of DSC configurations, resources, and tools.  This command is the global entry point for DSC builds controls the flow of operations.
        .Example
            $BuildParameters = @{
                WorkingDirectory = 'd:\gitlab\'
                DestinationRootDirectory = 'd:\PullServerOutputTest\'
                DestinationToolDirectory = 'd:\ToolsOutputTest\'
            }
            Invoke-DscBuild @BuildParameters
    #>
    [cmdletbinding(SupportsShouldProcess=$true)]
    param (
        #Root of your source control check outs or the folder above your Dsc_Configuration, Dsc_Resources, and Dsc_Tools directory.
        [parameter(mandatory)]
        [string]
        $WorkingDirectory,

        #Directory containing all the resources to process.  Defaults to a Dsc_Resources directory under the working directory.
        [parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $SourceResourceDirectory,

        #Directory containing all the tools to process.  Defaults to a Dsc_Tooling directory under the working directory.
        [parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $SourceToolDirectory,

        #Root of the location where pull server artificates (configurations and zipped resources) are published.
        [parameter(mandatory)]
        [string]
        $DestinationRootDirectory,

        #Destination for any tools that are published.
        [parameter(mandatory)]
        [string]
        $DestinationToolDirectory,

        #Modules to exclude from the resource testing and deployment process.
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ExcludedModules = @(),

        #The configuration data hashtable for the configuration to apply against.
        [parameter(mandatory)]
        [System.Collections.Hashtable]
        $ConfigurationData,

        #The name of the module to load that contains the configuration to run.
        [parameter(mandatory)]
        [string]
        $ConfigurationModuleName,

        #The name of the configuration to run.
        [parameter(mandatory)]
        [string]
        $ConfigurationName,

        #Custom location for the location of the DSC Build Tools modules.
        [parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $CurrentToolsDirectory,

        #This switch is used to indicate that configuration documents should be generated and deployed.
        [parameter()]
        [switch]
        $Configuration,

        #This switch is used to indicate that custom resources should be tested and deployed.
        [parameter()]
        [switch]
        $Resource,

        #This switch is used to indicate that the custom tools should be tested and deployed.
        [parameter()]
        [switch]
        $Tools,

        # Paths that should be in the PSModulePath during test execution.  $SourceResourceDirectory and $pshome\Modules are automatically included in this list.
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ModulePath
    )

    $script:DscBuildParameters = new-object PSObject -property $PSBoundParameters
    if (-not $PSBoundParameters.ContainsKey('SourceResourceDirectory')) {
        Add-DscBuildParameter -Name SourceResourceDirectory -value (Join-Path $WorkingDirectory 'Dsc_Resources')
    }
    if (-not $PSBoundParameters.ContainsKey('SourceToolDirectory')) {
        Add-DscBuildParameter -Name SourceToolDirectory -value (Join-Path $WorkingDirectory 'Dsc_Tooling')
    }
    if (-not $PSBoundParameters.ContainsKey('CurrentToolsDirectory')) {
        Add-DscBuildParameter -Name CurrentToolsDirectory -value (join-path $env:ProgramFiles 'WindowsPowerShell\Modules')
    }

    $ParametersToPass = @{}
    foreach ($key in ('Whatif', 'Verbose', 'Debug'))
    {
        if ($PSBoundParameters.ContainsKey($key)) {
            $ParametersToPass[$key] = $PSBoundParameters[$key]
        }
    }

    $originalPSModulePath = $env:PSModulePath

    try
    {
        $dirPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($script:DscBuildParameters.SourceResourceDirectory)

        $modulePaths = @(
            $dirPath
            Join-Path $pshome Modules
            $ModulePath
        )

        $env:PSModulePath = $modulePaths -join ';'

        Find-ModulesToPublish @ParametersToPass
        Clear-CachedDscResource @ParametersToPass

        Invoke-DscResourceUnitTest @ParametersToPass

        Copy-CurrentDscTools @ParametersToPass

        Test-DscResourceIsValid @ParametersToPass

        Assert-DestinationDirectory @ParametersToPass

        Invoke-DscConfiguration @ParametersToPass

        Compress-DscResourceModule @ParametersToPass
        Publish-DscToolModule @ParametersToPass
        Publish-DscResourceModule @ParametersToPass
        Publish-DscConfiguration @ParametersToPass
    }
    finally
    {
        $env:PSModulePath = $originalPSModulePath
    }
}
