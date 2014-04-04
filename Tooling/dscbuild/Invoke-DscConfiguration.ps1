function Invoke-DscConfiguration {
	[cmdletbinding()]
	param ()

    Write-Verbose 'Importing configuration module.'
    
    import-module $script:DscBuildParameters.ConfigurationModuleName -force -Verbose:$false 
    
    try
    {
        if ($script:DscBuildParameters.ShowConfigurationDebugMessages){
            $VerbosePreference = 'Continue'
            $DebugPreference = 'Continue'
        }
        Write-Verbose 'Starting to generate configurations.'
        Write-Verbose "`tWriting configurations to $($script:DscBuildParameters.ConfigurationOutputPath)"
        $ErrorActionPreference = 'Stop'
     
        . $script:DscBuildParameters.ConfigurationName -outputpath $script:DscBuildParameters.ConfigurationOutputPath -ConfigurationData $script:DscBuildParameters.ConfigurationData | 
            Out-Null
        Write-Verbose "Done creating configurations. Get ready for some pullin' baby!"
    }
    catch
    {
        Write-Warning 'Failed to generate configs.'
        throw 'Failed to generate configs.'
    }
    
    remove-module $script:DscBuildParameters.ConfigurationModuleName
}