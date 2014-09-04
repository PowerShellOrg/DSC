function Invoke-DscResourceUnitTest {
    [cmdletbinding(SupportsShouldProcess=$true)]
    param ()

    if ( Test-BuildResource ) {
        if ($pscmdlet.shouldprocess($script:DscBuildParameters.SourceResourceDirectory)) {
            Write-Verbose 'Running Resource Unit Tests.'

            $failCount = 0

            foreach ($module in $script:DscBuildParameters.ModulesToPublish)
            {
                $modulePath = Join-Path $script:DscBuildParameters.SourceResourceDirectory $module
                $result = Invoke-Pester -Path $modulePath -PassThru
                $failCount += $result.FailedCount
            }

            if ($failCount -gt 0)
            {
                throw "$failCount Resource Unit Tests were failed."
            }
        }
    }
}



