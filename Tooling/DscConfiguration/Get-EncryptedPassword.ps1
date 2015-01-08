function Get-DscEncryptedPassword
{
    [cmdletbinding(DefaultParameterSetName='ByStoreName')]
    param (
        [parameter(
            ParameterSetName = 'ByStoreName',
            ValueFromPipelineByPropertyName,
            Mandatory
        )]
        [Alias('BaseName')]
        [string]
        $StoreName,
        [parameter(
            ParameterSetName = 'ByStoreName'
        )]
        [string]
        $Path = (Join-path $script:ConfigurationDataPath 'Credentials'),
        [parameter(
            ParameterSetName = 'ByPipeline',
            ValueFromPipelineByPropertyName,
            Mandatory
        )]
        [Alias('FullName')]
        [string]
        $EncryptedFilePath,
        [parameter()]
        [string[]]
        $UserName
    )

    begin
    {
        if (-not $script:LocalCertificatePath -or -not (Test-Path -LiteralPath $script:LocalCertificatePath))
        {
            throw 'You must first set the local encryption certificate before calling Get-DscEncryptedPassword.  Use the Set-DscConfigurationCertificate command.'
        }
    }

    process
    {
        if (Test-LocalCertificate)
        {
            if (-not $PSBoundParameters.ContainsKey('EncryptedFilePath'))
            {
                $EncryptedFilePath = Join-Path $Path "$StoreName.psd1.encrypted"
            }

            Write-Verbose "Decrypting $EncryptedFilePath."
            $hashtable = $null

            try
            {
                $hashtable = Import-DscCredentialFile -Path $EncryptedFilePath -ErrorAction Stop

                if ($null -eq $hashtable)
                {
                    Write-Verbose "Failed to import $EncryptedFilePath with latest format.  Attempting legacy import."
                    $hashtable = Import-LegacyDscCredentialFile -EncryptedFilePath $EncryptedFilePath
                }
            }
            catch
            {
                Write-Error "Could not import encrypted credentials from file '$EncryptedFilePath': $($_.Exception.Message)"
                return
            }

            if ($PSBoundParameters.ContainsKey('UserName'))
            {
                $newHashTable = @{}
                foreach ($user in $UserName)
                {
                    $newHashTable[$user] = $hashtable[$user]
                }
                $hashtable = $newHashTable
            }

            return $hashtable
        }
    }
}

function Import-LegacyDscCredentialFile
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $EncryptedFilePath
    )

    $DecryptedDataFile = $null

    try
    {
        $DecryptedDataFile = ConvertFrom-EncryptedFile -path $EncryptedFilePath -CertificatePath $script:LocalCertificatePath -ErrorAction Stop

        Write-Verbose "Loading $($DecryptedDataFile.BaseName) into Credentials."
        $Credentials = Get-Hashtable $DecryptedDataFile.FullName -ErrorAction Stop

        return $Credentials | ConvertTo-CredentialLookup
    }
    catch
    {
        throw
    }
    finally
    {
        if ($null -ne $DecryptedDataFile)
        {
            Remove-PlainTextPassword $DecryptedDataFile.FullName
        }
    }
}