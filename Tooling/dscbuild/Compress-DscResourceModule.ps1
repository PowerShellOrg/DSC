function Compress-DscResourceModule {
    [cmdletbinding(SupportsShouldProcess=$true)]
    param ()

    if ( Test-BuildResource )  {
        if ($pscmdlet.shouldprocess("from $($script:DscBuildParameters.ProgramFilesModuleDirectory) to $($script:DscBuildParameters.ModuleOutputPath)")) {    
            Write-Verbose "Compressing tested modules: "
            foreach ($module in $script:DscBuildParameters.TestedModules) {
                Write-Verbose "`t$module"   
            }

        	Get-Item $script:DscBuildParameters.TestedModules | 
        		New-DscZipFile -ZipFile { join-path $script:DscBuildParameters.ModuleOutputPath "$($_.Name)" } -Force | 
                Foreach-Object {Write-Verbose "New compressed resource module $($_.fullname)"}
        }
    }
}

