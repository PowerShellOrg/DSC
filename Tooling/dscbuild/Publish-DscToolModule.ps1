function Publish-DscToolModule {
    [cmdletbinding(SupportsShouldProcess=$true)]
    param ()

    if (Test-BuildTools) {
        if ($pscmdlet.shouldprocess($script:DscBuildParameters.SourceToolDirectory)) {
            dir $script:DscBuildParameters.SourceToolDirectory -exclude '.g*', '.hg' |
                Test-ModuleVersion -Destination $script:DscBuildParameters.DestinationToolsDirectory |
                copy-item -recurse -force -destination $script:DscBuildParameters.DestinationToolsDirectory
        }
    }
}


