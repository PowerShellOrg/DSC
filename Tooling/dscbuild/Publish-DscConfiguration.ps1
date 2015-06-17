function Publish-DscConfiguration {
    [cmdletbinding(SupportsShouldProcess=$true)]
    param ()

    if ( Test-BuildConfiguration ) {

        Write-Verbose 'Moving Configuration MOFs from '
        Write-Verbose "`t$($script:DscBuildParameters.ConfigurationOutputPath) to"
        Write-Verbose "`t$($script:DscBuildParameters.DestinationConfigurationDirectory)"
        if ($pscmdlet.shouldprocess("$($script:DscBuildParameters.ConfigurationOutputPath) to $($script:DscBuildParameters.DestinationConfigurationDirectory)")) {
            dir (join-path $script:DscBuildParameters.ConfigurationOutputPath '*.mof') |
                foreach-object { Write-Verbose "Moving $($_.name) to $($script:DscBuildParameters.DestinationConfigurationDirectory)"; $_ } |
                Move-Item -Destination $script:DscBuildParameters.DestinationConfigurationDirectory -force -PassThru |
                New-DscChecksumFile -Verbose:$false
        }
    }
    else {
        Write-Warning "Skipping publishing configurations."
    }
}


