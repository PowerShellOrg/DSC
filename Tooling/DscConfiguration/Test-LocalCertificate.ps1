function Test-LocalCertificate
{
    param ()
    if (-not [string]::IsNullOrEmpty($LocalCertificateThumbprint))
    {
        Write-Verbose 'LocalCertificateThumbprint is present.'
        if (Test-Path $LocalCertificatePath)
        {
            Write-Verbose 'Certficate is present in the local certificate store.'
            return $true
        }
        else
        {
            Write-Warning 'Certficate specified is not in the certificate store.'
            return $false
        }
    }
    else
    {
        Write-Warning 'No local certificate supplied or configured with the DSC Local Configuration Manager.'
        return $false
    }
}




