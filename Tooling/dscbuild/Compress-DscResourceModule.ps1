function Compress-DscResourceModule {
    [cmdletbinding()]
    param ()

    if ($script:DscBuildParameters.SkipResourcePackaging) {
        Write-Verbose "Skipping resource packaging."
    }
    else {
    	$ProgramFilesModules = join-path $env:ProgramFiles 'WindowsPowerShell\Modules'
    	Dir $ProgramFilesModules -Directory | 
    		New-DscZipFile -ZipFile { join-path $script:DscBuildParameters.ModuleOutputPath "$($_.Name).zip" } -Force | 
            Foreach-Object {Write-Verbose "New compressed resource module $($_.fullname)"}
    }
}