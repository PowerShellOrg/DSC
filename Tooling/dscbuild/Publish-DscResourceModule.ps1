function Publish-DscResourceModule {
    [cmdletbinding(SupportsShouldProcess=$true)]
    param ()

    if ( Test-BuildResource ) {
        Write-Verbose 'Moving Processed Resource Modules from '
        Write-Verbose "`t$($script:DscBuildParameters.ModuleOutputPath) to"
        Write-Verbose "`t$($script:DscBuildParameters.DestinationModuleDirectory)"

        if ($pscmdlet.shouldprocess("$($script:DscBuildParameters.ModuleOutputPath) to $($script:DscBuildParameters.DestinationModuleDirectory)")) {

            Get-ChildItem (Join-Path $script:DscBuildParameters.ModuleOutputPath '*.zip') |
                ForEach-Object { Write-Verbose "Moving $($_.name) to $($script:DscBuildParameters.DestinationModuleDirectory)"; $_ } |
                Move-Item -Destination $script:DscBuildParameters.DestinationModuleDirectory -PassThru -Force |
                New-DscChecksumFile -Verbose:$false
        }
    }
}




