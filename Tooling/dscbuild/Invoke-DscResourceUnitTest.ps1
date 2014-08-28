function Invoke-DscResourceUnitTest {
    [cmdletbinding(SupportsShouldProcess=$true)]
    param ()

    if ( Test-BuildResource ) {
        if ($pscmdlet.shouldprocess($script:DscBuildParameters.SourceResourceDirectory)) {
            Write-Verbose 'Running Resource Unit Tests.'
            $result = Invoke-Pester -Path $script:DscBuildParameters.SourceResourceDirectory -PassThru
            $failCount = $result.FailedCount

            if ($failCount -gt 0)
            {
                throw "$failCount Resource Unit Tests were failed."
            }
        }
    }
}



