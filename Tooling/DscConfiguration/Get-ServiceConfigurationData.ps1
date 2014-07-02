function Get-ServiceConfigurationData
{
    [cmdletbinding()]
    param ()
    if (($script:ConfigurationData.Services.Keys.Count -eq 0))
    { 
        Write-Verbose "Processing Services from $($script:ConfigurationDataPath))." 
        foreach ( $item in (dir (join-path $script:ConfigurationDataPath 'Services\*.psd1')) )
        {
            Write-Verbose "Loading data for site $($item.basename) from $($item.fullname)."
            $script:ConfigurationData.Services.Add($item.BaseName, (Get-Hashtable $item.FullName))
        }
    }
}



