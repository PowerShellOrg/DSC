function Copy-CurrentDscResource {
    [cmdletbinding()]
    param ()

    $ProgramFilesModules = join-path $env:ProgramFiles 'WindowsPowerShell\Modules'
    Write-Verbose "Pushing new configuration modules to $ProgramFilesModules."
    dir $script:DscBuildParameters.SourceModuleRoot | 
        Where-Object {$script:DscBuildParameters.ExcludedModules -notcontains $_.name} |
        Copy-Item -Destination $ProgramFilesModules  -Recurse -Force
}