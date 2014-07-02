function Publish-DscResourceModule {
    [cmdletbinding(SupportsShouldProcess=$true)]
    param ()
    
    if ( Test-BuildResource ) {
        Write-Verbose 'Moving Processed Resource Modules from '
        Write-Verbose "`t$($script:DscBuildParameters.ModuleOutputPath) to"
        Write-Verbose "`t$($script:DscBuildParameters.DestinationModuleDirectory)"

        if ($pscmdlet.shouldprocess("$($script:DscBuildParameters.ModuleOutputPath) to $($script:DscBuildParameters.DestinationModuleDirectory)")) {               
        
        	Dir (join-path $script:DscBuildParameters.ModuleOutputPath '*.zip') | 
                foreach-object { Write-Verbose "Checking if $($_.name) is already at $($script:DscBuildParameters.DestinationModuleDirectory)"; $_ } |
        		Where-Object {-not (Test-Path (Join-Path $script:DscBuildParameters.DestinationModuleDirectory $_.name))} |
                foreach-object { Write-Verbose "Moving $($_.name) to $($script:DscBuildParameters.DestinationModuleDirectory)"; $_ } |
        		Move-Item -Destination $script:DscBuildParameters.DestinationModuleDirectory -PassThru |        
                New-DscChecksumFile -Verbose:$false
        }
    }
}



