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
