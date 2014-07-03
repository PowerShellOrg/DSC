function Copy-CurrentDscResource {
    [cmdletbinding(SupportsShouldProcess=$true)]
    param ()
    
    Write-Verbose ''
    Write-Verbose "Pushing new configuration modules from $($script:DscBuildParameters.SourceResourceDirectory) to $($script:DscBuildParameters.ProgramFilesModuleDirectory)."

    if ($pscmdlet.shouldprocess("$($script:DscBuildParameters.SourceResourceDirectory) to $($script:DscBuildParameters.ProgramFilesModuleDirectory)")) {                
        dir $script:DscBuildParameters.SourceResourceDirectory -exclude '.g*', '.hg'  |             
            Where-Object {$script:DscBuildParameters.ExcludedModules -notcontains $_.name} |
            Test-ModuleVersion -Destination $script:DscBuildParameters.ProgramFilesModuleDirectory |            
            Copy-Item -Destination $script:DscBuildParameters.ProgramFilesModuleDirectory -Recurse -Force
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