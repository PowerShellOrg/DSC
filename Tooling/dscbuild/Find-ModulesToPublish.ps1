function Find-ModulesToPublish {
    [CmdletBinding(SupportsShouldProcess)]
    param ()

    if ( Test-BuildResource ) {
        $ModulesToPublish = @(
            Get-ChildItem $script:DscBuildParameters.SourceResourceDirectory -Exclude '.g*', '.hg' -Directory |
            Where-Object { $script:DscBuildParameters.ExcludedModules -notcontains $_.Name } |
            ForEach-Object {
                $source = $_

                $sourceVersion = Get-ModuleVersion -Path $source.FullName -AsVersion
                $publishTarget = Join-Path -Path $script:DscBuildParameters.DestinationRootDirectory -ChildPath "Modules\$($source.Name)_$sourceVersion"

                $zipExists      = Test-Path -Path "$publishTarget.zip"
                $checksumExists = Test-Path -Path "$publishTarget.zip.checksum"

                if (-not ($zipExists -and $checksumExists))
                {
                    $source.Name
                }
            }
        )

        Add-DscBuildParameter -Name ModulesToPublish -Value $ModulesToPublish
    }
}


