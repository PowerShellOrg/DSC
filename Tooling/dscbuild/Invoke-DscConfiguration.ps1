function Invoke-DscConfiguration {
    [cmdletbinding(SupportsShouldProcess=$true)]
    param ()

    if ( Test-BuildConfiguration )
    {
        if ( $pscmdlet.shouldprocess("Configuration module $($script:DscBuildParameters.ConfigurationModuleName) and configuration $($script:DscBuildParameters.ConfigurationName)") ) {
            Write-Verbose ''
            Write-Verbose "Importing configuration module: $($script:DscBuildParameters.ConfigurationModuleName)"
            if (Get-Module -list -name "$($script:DscBuildParameters.ConfigurationModuleName)") {

                $ResetVerbosePreference = $false
                if ($PSBoundParameters.ContainsKey('Verbose') -and $PSBoundParameters['Verbose'].IsPresent) {
                    $ResetVerbosePreference = $true
                    $VerbosePreference = 'SilentlyContinue'
                }

                try  {
                    import-module -name "$($script:DscBuildParameters.ConfigurationModuleName)" -force -Verbose:$false -ErrorAction Stop
                }
                catch {

                    Write-Warning "Failed to load configuration module: $($script:DscBuildParameters.ConfigurationModuleName)"
                    $Exception = $_.Exception
                    do {
                        Write-Warning "`t$($_.Message)"
                        $Exception = $_.InnerException
                    } while ($Exception -ne $null)
                    throw "Failed to load $($script:DscBuildParameters.ConfigurationModuleName)"
                }

                if ($ResetVerbosePreference) {
                    $VerbosePreference = 'Continue'
                }
                Write-Verbose "Imported $($script:DscBuildParameters.ConfigurationModuleName)"
                Write-Verbose ''
            }
            else {
                Write-Warning "Unable to resolve the module '$($script:DscBuildParameters.ConfigurationModuleName)'"
                Write-Warning "Current modules on PSModulePath"
                $env:psmodulepath -split ';' |
                    get-childitem -directory |
                    foreach {
                        Write-Warning "`tFound $($_.Name)"
                    }
                throw "Failed to load configuration module"
            }

            try
            {
                Write-Verbose ""
                Write-Verbose 'Starting to generate configurations.'
                Write-Verbose "`tWriting configurations to $($script:DscBuildParameters.ConfigurationOutputPath)"
                $ErrorActionPreference = 'Stop'

                $output = . $script:DscBuildParameters.ConfigurationName -outputpath $script:DscBuildParameters.ConfigurationOutputPath -ConfigurationData $script:DscBuildParameters.ConfigurationData

                Write-Verbose "Done creating configurations. Get ready for some pullin' baby!"
                Write-Verbose ""
            }
            catch
            {
                Write-Warning 'Failed to generate configs.'
                throw 'Failed to generate configs.'
            }


            remove-module $script:DscBuildParameters.ConfigurationModuleName
        }
    }
}


