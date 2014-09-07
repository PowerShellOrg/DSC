function Clear-InstalledDscResource {
    [cmdletbinding(SupportsShouldProcess=$true)]
    param ()

    if ( Test-BuildResource ) {
        $ModulesToPublish = @()

        if ($pscmdlet.shouldprocess("$($script:DscBuildParameters.ProgramFilesModuleDirectory)) based on modules in $($script:DscBuildParameters.SourceResourceDirectory)")) {
            Write-Verbose 'Clearing Program Files from old configuration modules.'
            Get-ChildItem $script:DscBuildParameters.SourceResourceDirectory -Exclude '.g*', '.hg' -Directory |
            Where-Object { $script:DscBuildParameters.ExcludedModules -notcontains $_.Name } |
            ForEach-Object {
                $source = $_
                $dest = Join-Path $script:DscBuildParameters.ProgramFilesModuleDirectory $source.Name

                $sourceVersion = Get-ModuleVersion -Path $source.FullName -AsVersion
                $publishTarget = Join-Path -Path $script:DscBuildParameters.DestinationRootDirectory -ChildPath "Modules\$($source.Name)_$sourceVersion"

                $shouldPublish = $true

                if (Test-Path -Path $dest -PathType Container)
                {
                    if ((Test-ModuleVersion -InputObject $source -Destination $script:DscBuildParameters.ProgramFilesModuleDirectory) -or
                        -not (Test-Path -Path "$publishTarget.zip") -or
                        -not (Test-Path -Path "$publishTarget.zip.checksum"))
                    {
                        Remove-Item $dest -Force -Recurse
                    }
                    else
                    {
                        $shouldPublish = $false
                    }
                }

                if ($shouldPublish)
                {
                    $ModulesToPublish += $source.Name
                }
            }
        }

        Add-DscBuildParameter -Name ModulesToPublish -Value $ModulesToPublish
    }
}


