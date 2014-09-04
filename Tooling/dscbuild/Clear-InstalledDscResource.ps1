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

                if (Test-Path -Path $dest -PathType Container)
                {
                    if (Test-ModuleVersion -InputObject $source -Destination $script:DscBuildParameters.ProgramFilesModuleDirectory)
                    {
                        Remove-Item $dest -Force -Recurse
                        $ModulesToPublish += $source.Name
                    }
                }
                else
                {
                    $ModulesToPublish += $source.Name
                }
            }
        }

        Add-DscBuildParameter -Name ModulesToPublish -Value $ModulesToPublish
    }
}


