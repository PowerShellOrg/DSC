function Add-DscEncryptedPassword
{
    [CmdletBinding(DefaultParameterSetName = 'Credential')]
    param (
        [parameter(mandatory)]
        [string] $StoreName,

        [parameter()]
        [string] $Path = (Join-path $script:ConfigurationDataPath 'Credentials'),

        [Parameter(Mandatory, ParameterSetName = 'Credential')]
        [pscredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Parameter(Mandatory, ParameterSetName = 'PasswordString')]
        [Parameter(Mandatory, ParameterSetName = 'PasswordSecureString')]
        [string] $UserName,

        [string] $FriendlyName, 
        [Parameter(Mandatory, ParameterSetName = 'PasswordSecureString')]
        [securestring] $SecurePassword,

        [Parameter(Mandatory, ParameterSetName = 'PasswordString')]
        [string] $Password
    )

    if (-not $script:LocalCertificatePath -or -not (Test-Path -LiteralPath $script:LocalCertificatePath))
    {
        throw 'You must first set the local encryption certificate before calling Add-DscEncryptedPassword.  Use the Set-DscConfigurationCertificate command.'
    }

    switch ($PSCmdlet.ParameterSetName)
    {
        'PasswordString'
        {
            $Credential = New-Credential $UserName $Password
        }

        'PasswordSecureString'
        {
            $Credential = New-Credential $UserName $SecurePassword
        }
    }

    if (-not ($FriendlyName)) {
      $FriendlyName = $Credential.UserName
    }

    $encryptedFilePath = Join-Path $Path "$StoreName.psd1.encrypted"

    $hashtable = @{}

    if (Test-Path -Path $encryptedFilePath)
    {
        Write-Verbose "Credential file $encryptedFilePath already exists; importing its contents..."

        $hashtable = Get-DscEncryptedPassword -StoreName $StoreName -Path $Path
        if ($hashtable -isnot [hashtable])
        {
            # Shouldn't happen; would indicate a bug in Get-DscEncryptedPassword or its helper functions
            if ($null -eq $hashtable)
            {
                $type = 'Null'
            }
            else
            {
                $type = $hashtable.GetType().FullName
            }

            throw "Get-DscEncryptedPassword function returned an object of type $type instead of a Hashtable."
        }

        Write-Verbose "$encryptedFilePath imported successfully.  Current credential count: $($hashtable.Count)"
    }

    Write-Verbose "Adding credential for user $($Credential.UserName)"

    if ($hashtable.ContainsKey($FriendlyName)) { 
      
      $hashtable[$FriendlyName] = $Credential
    }
    else {
      
      $hashtable += @{ $friendlyname = $Credential}
    }

    Export-DscCredentialFile -Hashtable $hashtable -Path $encryptedFilePath
}

Set-Alias -Name 'Add-EncryptedPassword' -value 'Add-DscEncryptedPassword'
