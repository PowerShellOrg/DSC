function Get-AllNodesConfigurationData
{
    [cmdletbinding()]
    param ()
    if (($script:ConfigurationData.AllNodes.Count -eq 0))
    {  
        Write-Verbose "Processing AllNodes from $($script:ConfigurationDataPath)."
        $script:ConfigurationData.AllNodes = @()
        dir (join-path $script:ConfigurationDataPath 'AllNodes\*.psd1') | 
            Get-Hashtable | 
            foreach-object { 
                Write-Verbose "Adding Name: $($_.Name)"
                $script:ConfigurationData.AllNodes += $_ 
            }
    }
}



