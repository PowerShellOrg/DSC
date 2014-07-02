function Invoke-DscResourceUnitTest {
    [cmdletbinding(SupportsShouldProcess=$true)]
    param ()
    
    if ( Test-BuildResource ) {     
        if ($pscmdlet.shouldprocess($script:DscBuildParameters.SourceResourceDirectory)) {
            Write-Verbose 'Running Resource Unit Tests.'
            Invoke-Pester -relative_path $script:DscBuildParameters.SourceResourceDirectory
        }           
    }    
}


