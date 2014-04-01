function Clear-InstalledDscResource {
    [cmdletbinding()]
    param ()

    $ProgramFilesModules = join-path $env:ProgramFiles 'WindowsPowerShell\Modules'
    Write-Verbose 'Clearing Program Files from old configuration modules.'
    dir $script:DscBuildParameters.SourceModuleRoot |
        Foreach { dir (join-path $ProgramFilesModules $_.Name) -erroraction SilentlyContinue } |
        Remove-Item -Force -Recurse
}