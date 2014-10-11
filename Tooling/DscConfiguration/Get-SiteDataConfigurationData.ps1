function Get-SiteDataConfigurationData
{
    [cmdletbinding()]
    param ()

    $sitePath = Join-Path -Path $script:ConfigurationDataPath -ChildPath 'SiteData\*.psd1'

    if (($script:ConfigurationData.SiteData.Keys.Count -eq 0) -and
        (Test-Path -Path $sitePath))
    {
        Write-Verbose "Processing SiteData from $($script:ConfigurationDataPath))."
        foreach ( $item in (Get-ChildItem $sitePath) )
        {
            Write-Verbose "Loading data for site $($item.basename) from $($item.fullname)."
            $script:ConfigurationData.SiteData.Add($item.BaseName, (Get-Hashtable $item.FullName))
        }
    }
}




