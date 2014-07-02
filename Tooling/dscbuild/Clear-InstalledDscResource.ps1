function Clear-InstalledDscResource {
    [cmdletbinding(SupportsShouldProcess=$true)]
    param ()

    if ( Test-BuildResource ) {        
        if ($pscmdlet.shouldprocess("$($script:DscBuildParameters.ProgramFilesModuleDirectory)) based on modules in $($script:DscBuildParameters.SourceResourceDirectory)")) {            
            Write-Verbose 'Clearing Program Files from old configuration modules.'
            dir $script:DscBuildParameters.SourceResourceDirectory |
                Foreach { dir (join-path $script:DscBuildParameters.ProgramFilesModuleDirectory $_.Name) -erroraction SilentlyContinue } |
                Remove-Item -Force -Recurse
        }
    }
}

