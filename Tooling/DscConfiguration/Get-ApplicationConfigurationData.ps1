function Get-ApplicationConfigurationData {
	[cmdletbinding()]
    param ()
    if (($script:ConfigurationData.Applications.Keys.Count -eq 0))
    { 
        Write-Verbose "Processing Applications from $($script:ConfigurationDataPath))." 
        foreach ( $item in (dir (join-path $script:ConfigurationDataPath 'Applications\*.psd1')) )
        {
            Write-Verbose "Loading data for site $($item.basename) from $($item.fullname)."
            $script:ConfigurationData.Applications += (Get-Hashtable $item.FullName)
        }
    }
}
