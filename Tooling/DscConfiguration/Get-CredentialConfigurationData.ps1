function Get-CredentialConfigurationData
{
    [cmdletbinding()]
    param ()
    if (($script:ConfigurationData.Credentials.Keys.Count -eq 0) )
    { 
        Write-Verbose "Processing Credentials from $($script:ConfigurationDataPath))."
        
        $script:ConfigurationData.Credentials = dir (join-path $script:ConfigurationDataPath 'Credentials\*.psd1.encrypted') | 
            Get-DscEncryptedPassword -StoreName {$_.Name -replace '\.encrypted' -replace '\.psd1'} |
            ConvertTo-CredentialLookup
        
    }
}



