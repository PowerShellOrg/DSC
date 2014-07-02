function Test-DscResourceIsValid {
	[cmdletbinding(SupportsShouldProcess=$true)]
	param ()

	
    if ( Test-BuildResource ) {
        if ($pscmdlet.shouldprocess("modules from $($script:DscBuildParameters.ProgramFilesModuleDirectory)")) {
        	dir $script:DscBuildParameters.ProgramFilesModuleDirectory | 
                Where-DscResource -IsValid | 
                Out-Null        
        }
    }
}

