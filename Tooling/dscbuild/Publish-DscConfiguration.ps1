function Publish-DscConfiguration {
    [cmdletbinding()]
    param ()

    Write-Verbose 'Moving Processed Resource Modules from '
    Write-Verbose "`t$($script:DscBuildParameters.ConfigurationOutputPath) to"
    Write-Verbose "`t$($script:DscBuildParameters.DestinationConfigurationDirectory)"

    dir (join-path $script:DscBuildParameters.ConfigurationOutputPath '*.mof') | 
        foreach-object { Write-Verbose "Moving $($_.name) to $($script:DscBuildParameters.DestinationConfigurationDirectory)"; $_ } |
        Move-Item -Destination $script:DscBuildParameters.DestinationConfigurationDirectory -force -PassThru |        
        New-DscChecksumFile -Verbose:$false
}