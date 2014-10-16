function Get-CredentialConfigurationData
{
    [cmdletbinding()]
    param ()

    $credentialsPath = Join-Path -Path $script:ConfigurationDataPath -ChildPath 'Credentials\*.psd1.encrypted'

    if (($script:ConfigurationData.Credentials.Keys.Count -eq 0) -and
        (Test-Path -Path $credentialsPath))
    {
        Write-Verbose "Processing Credentials from $($script:ConfigurationDataPath))."

        $script:ConfigurationData.Credentials = Get-ChildItem -Path $credentialsPath |
            Get-DscEncryptedPassword -StoreName { $_.Name -replace '\.encrypted' -replace '\.psd1' }
    }
}




