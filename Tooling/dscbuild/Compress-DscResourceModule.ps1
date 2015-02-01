function Compress-DscResourceModule {
    [cmdletbinding(SupportsShouldProcess=$true)]
    param ()

    if ( Test-BuildResource )  {
        if ($pscmdlet.shouldprocess("from $($script:DscBuildParameters.SourceResourceDirectory) to $($script:DscBuildParameters.ModuleOutputPath)")) {
            Write-Verbose "Compressing tested modules: "
            foreach ($module in $script:DscBuildParameters.TestedModules) {
                Write-Verbose "`t$module"
            }

            if ($script:DscBuildParameters.TestedModules.Count -gt 0)
            {
                $guid = [guid]::NewGuid().Guid
                $tempFolder = Join-Path $env:temp $guid

                $null = New-Item -ItemType Directory -Path $tempFolder

                $zipSources = @(
                    foreach ($source in $script:DscBuildParameters.TestedModules)
                    {
                        $moduleName = Split-Path $source -Leaf
                        $targetPath = Join-Path $tempFolder $moduleName

                        $null = New-Item -ItemType Directory -Path $targetPath

                        $deployScript = Join-Path $source Deploy.ps1

                        if (Test-Path $deployScript -PathType Leaf)
                        {
                            Write-Verbose "Executing Deploy.ps1 script for module $moduleName."
                            $null = & $deployScript $targetPath
                        }
                        else
                        {
                            Write-Verbose "Module $moduleName has no Deploy.ps1 script; publishing entire source folder."
                            Copy-Item $source\* $targetPath\ -Recurse -Force
                        }

                        $targetPath
                    }
                )

                if ($zipSources.Count -gt 0)
                {
                    Get-Item $zipSources |
                        New-DscZipFile -ZipFile { join-path $script:DscBuildParameters.ModuleOutputPath "$($_.Name)" } -Force |
                        Foreach-Object {Write-Verbose "New compressed resource module $($_.fullname)"}
                }
            }
        }
    }
}
