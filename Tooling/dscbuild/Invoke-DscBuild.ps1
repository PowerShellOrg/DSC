function Invoke-DscBuild 
{
    param (
        [parameter(mandatory)]
        [string]
        $WorkingDirectory,
        [parameter(mandatory)]
        [string]
        $DestinationDirectory,
        [parameter()]
        [switch]
        $SkipResourceCheck,
        [parameter()]
        [switch]
        $SkipResourcePackaging,
        [parameter(mandatory)]
        [string]
        $SourceModuleRoot,
        [parameter(mandatory)]
        [string[]]
        $ExcludedModules,
        [parameter(mandatory)]
        [System.Collections.Hashtable]
        $ConfigurationData, 
        [parameter(mandatory)]
        [string]
        $ConfigurationName,
        [parameter(mandatory)]
        [string]
        $ConfigurationModuleName

    )

    $script:DscBuildParameters = new-object PSObject -property $PSBoundParameters
    
    Clear-InstalledDscResource    
    Clear-CachedDscResource

    Invoke-DscResourceUnitTest
    Copy-CurrentDscResource
    Test-DscResourceIsValid
    
    Assert-DestinationDirectory

    Invoke-DscConfiguration
    
    Compress-DscResourceModule
    Publish-DscResourceModule
    Publish-DscConfiguration
}
