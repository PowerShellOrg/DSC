function Invoke-DscConfiguration {
	[cmdletbinding()]
	param ()

    Write-Verbose 'Importing configuration module.'
    if (Get-Module -list -name "$($script:DscBuildParameters.ConfigurationModuleName)") {
        import-module  -name "$($script:DscBuildParameters.ConfigurationModuleName)" -force -Verbose:$false     
    } 
    else {
        Write-Warning "Unable to resolve the module '$($script:DscBuildParameters.ConfigurationModuleName)'"
        Write-Warning "Current modules on PSModulePath"
        dir ($env:psmodulepath -split ';') | foreach {
            Write-Warning "`tFound $($_.Name)"
        }
        throw "Failed to load configuration module"
    }

    try
    {
        Write-Verbose 'Starting to generate configurations.'
        Write-Verbose "`tWriting configurations to $($script:DscBuildParameters.ConfigurationOutputPath)"
        $ErrorActionPreference = 'Stop'

        $output = . $script:DscBuildParameters.ConfigurationName -outputpath $script:DscBuildParameters.ConfigurationOutputPath -ConfigurationData $script:DscBuildParameters.ConfigurationData         
        
        Write-Verbose "Done creating configurations. Get ready for some pullin' baby!"
    }
    catch
    {
        Write-Warning 'Failed to generate configs.'        
        throw 'Failed to generate configs.'
    }
    
    
    remove-module $script:DscBuildParameters.ConfigurationModuleName
}