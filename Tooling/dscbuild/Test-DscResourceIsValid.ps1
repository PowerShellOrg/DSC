function Test-DscResourceIsValid {
	[cmdletbinding()]
	param ()

	$ProgramFilesModules = join-path $env:ProgramFiles 'WindowsPowerShell\Modules'
    if ($script:DscBuildParameters.SkipResourceCheck) {
        Write-Verbose "Skipping Dsc Resource Validation."
    }
    else {        
    	dir $ProgramFilesModules | 
            Where-DscResource -IsValid | 
            Out-Null        
    }
}