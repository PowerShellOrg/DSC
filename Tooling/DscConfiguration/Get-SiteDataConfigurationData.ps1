function Get-SiteDataConfigurationData
{
    [cmdletbinding()]
    param ()
    if (($script:ConfigurationData.SiteData.Keys.Count -eq 0))
    { 
        Write-Verbose "Processing SiteData from $($script:ConfigurationDataPath))." 
        foreach ( $item in (dir (join-path $script:ConfigurationDataPath 'SiteData\*.psd1')) )
        {
            Write-Verbose "Loading data for site $($item.basename) from $($item.fullname)."
            $script:ConfigurationData.SiteData.Add($item.BaseName, (Get-Hashtable $item.FullName))
        }
    }
}



