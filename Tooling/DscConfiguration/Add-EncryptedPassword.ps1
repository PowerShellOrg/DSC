function Add-DscEncryptedPassword
{
    param (                
        [parameter(mandatory)]
        [string]
        $StoreName,
        [parameter()]
        [string]
        $Path = (Join-path $script:ConfigurationDataPath 'Credentials'), 
        [parameter()]
        [string]
        $UserName, 
        [parameter()]
        [string]
        $Password
    )
    
    $EncryptedFilePath = Join-Path $Path "$StoreName.psd1.encrypted"
    $FilePath = Join-Path $Path "$StoreName.psd1"

    $Credentials = @{}
    if (Test-Path $EncryptedFilePath)
    {
        $Credentials += Get-DscEncryptedPassword -StoreName $StoreName -Path $Path
        Remove-Item $EncryptedFilePath
        foreach ($key in $Credentials.Keys)
        {
            Write-Verbose "Found credentials for $username."
        }
    }
        
    $Credentials.Add($UserName, $Password)
    Write-Verbose "Adding credentials for $Username. ($($credentials.keys.count) total.)"

    if (Test-Path $FilePath)
    {
        Remove-Item $FilePath -Confirm:$false
    }    
    
    '@{' | Out-File $FilePath 
    foreach ($key in $Credentials.Keys)
    {
        Write-Verbose "Persisting credentials for $key to disk."
        "'$key' = '$($Credentials[$key])'" | Out-File $FilePath -Append
    }
    '}' | Out-File $FilePath -Append

    Write-Verbose 'Encrypting credentials.'
    ConvertTo-EncryptedFile -Path $FilePath -CertificatePath $LocalCertificatePath
    Remove-PlainTextPassword $FilePath
}

Set-Alias -Name 'Add-EncryptedPassword' -value 'Add-DscEncryptedPassword'

