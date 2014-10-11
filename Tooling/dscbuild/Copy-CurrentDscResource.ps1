function Copy-CurrentDscResource {
    [cmdletbinding(SupportsShouldProcess=$true)]
    param ()

    Write-Verbose ''
    Write-Verbose "Pushing new configuration modules from $($script:DscBuildParameters.SourceResourceDirectory) to $($script:DscBuildParameters.ProgramFilesModuleDirectory)."

    if ($pscmdlet.shouldprocess("$($script:DscBuildParameters.SourceResourceDirectory) to $($script:DscBuildParameters.ProgramFilesModuleDirectory)")) {
        foreach ($module in $script:DscBuildParameters.ModulesToPublish)
        {
            $modulePath = Join-Path $script:DscBuildParameters.SourceResourceDirectory $module
            Copy-Item -Path $modulePath -Destination $script:DscBuildParameters.ProgramFilesModuleDirectory -Recurse -Force
        }
    }
}

function Copy-CurrentDscTools {
    [cmdletbinding(SupportsShouldProcess=$true)]
    param ()

    Write-Verbose ''
    Write-Verbose "Pushing new tools modules from $($script:DscBuildParameters.SourceToolDirectory) to $($script:DscBuildParameters.CurrentToolsDirectory)."

    if ($pscmdlet.shouldprocess("$($script:DscBuildParameters.SourceToolDirectory) to $($script:DscBuildParameters.CurrentToolsDirectory)")) {
        dir $script:DscBuildParameters.SourceToolDirectory -exclude '.g*', '.hg' |
            Test-ModuleVersion -Destination $script:DscBuildParameters.CurrentToolsDirectory |
            Copy-Item -Destination $script:DscBuildParameters.CurrentToolsDirectory -Recurse -Force
    }
    Write-Verbose ''
}
