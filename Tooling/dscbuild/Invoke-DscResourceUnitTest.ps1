function Invoke-DscResourceUnitTest {
    [cmdletbinding()]
    param ()
    
    if ($script:DscBuildParameters.SkipResourceCheck)
    {
        Write-Verbose "Skipping unit tests of the resources."
    }
    else {
        Write-Verbose 'Running Resource Unit Tests.'
        Invoke-Pester -relative_path $script:DscBuildParameters.SourceModuleRoot   
    }    
}
