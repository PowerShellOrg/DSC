function Get-AllNodesConfigurationData
{
    [cmdletbinding()]
    param ()

    $nodePath = Join-Path -Path $script:ConfigurationDataPath -ChildPath 'AllNodes\*.psd1'

    if (($script:ConfigurationData.AllNodes.Count -eq 0) -and
        (Test-Path -Path $nodePath))
    {
        Write-Verbose "Processing AllNodes from $($script:ConfigurationDataPath)."
        $script:ConfigurationData.AllNodes = @()

        $script:ConfigurationData.AllNodes = @(
            Get-ChildItem $nodePath |
            Get-Hashtable |
            ForEach-Object {
                Write-Verbose "Adding Node: $($_.Name)"
                $_
            }
        )
    }
}




