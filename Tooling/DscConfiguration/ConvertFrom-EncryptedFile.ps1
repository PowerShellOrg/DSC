Function ConvertFrom-EncryptedFile
{
    [cmdletbinding(DefaultParameterSetName='LocalCertStoreAndFilePath')]
    Param(
        [Parameter(
            Position=0,
            Mandatory = $true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'LocalCertStoreAndFilePath'
        )]
        [Parameter(
            Position=0,
            Mandatory = $true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ArbitraryCertAndFilePath'
        )]
        [string]
        $Path,

        [Parameter(
            Position=0,
            Mandatory = $true,
            ValueFromPipeline=$true,
            ParameterSetName = 'LocalCertStoreAndInputObject'
        )]
        [Parameter(
            Position=0,
            Mandatory = $true,
            ValueFromPipeline=$true,
            ParameterSetName = 'ArbitraryCertAndInputObject'
        )]
        [System.IO.FileInfo]
        $InputObject,

        #Can be a path to the local cert store like Cert:\CurrentUser\My\9554F368FEA619A655A1D49408FC13C3E0D60E11
        [Parameter(
            mandatory=$true,
            position = 1,
            ParameterSetName = 'LocalCertStoreAndFilePath'
        )]
        [Parameter(
            mandatory=$true,
            position = 1,
            ParameterSetName = 'LocalCertStoreAndInputObject'
        )]
        [string]
        $CertificatePath,

        #Must be a System.Security.Cryptography.X509Certificates.X509Certificate2 object
        [Parameter(
            mandatory=$true,
            position = 1,
            ParameterSetName = 'ArbitraryCertAndInputObject'
        )]
        [Parameter(
            mandatory=$true,
            position = 1,
            ParameterSetName = 'ArbitraryCertAndFilePath'
        )]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate,
        [parameter()]
        [string]
        $FileExtension = 'encrypted'
    )

    begin
    {
        $cert = $Certificate

        switch ($PSCmdlet.ParameterSetName)
        {
            'LocalCertStoreAndFilePath' { Write-Verbose "Loading certificate from $CertificatePath"; $cert = Get-Item $CertificatePath }
            'LocalCertStoreAndInputObject' { Write-Verbose "Loading certificate from $CertificatePath"; $cert = Get-Item $CertificatePath ; $Path = $InputObject.FullName }
            'ArbitraryCertAndInputObject' { $Path = $InputObject.FullName }
        }

        if ($cert -isnot [System.Security.Cryptography.X509Certificates.X509Certificate2])
        {
            throw 'Specified certificate was not found'
        }
        elseif($cert.HasPrivateKey -eq $False -or $cert.PrivateKey -eq $null)
        {
            throw 'The supplied certificate does not contain a private key, or it could not be accessed.'
        }
    }

    process
    {
        $CryptoStream = $null
        $FileStreamWriter = $null
        $FileStreamReader = $null

        try
        {
            $Path = (Resolve-Path $Path -ErrorAction Stop).ProviderPath

            $AesProvider                = New-Object System.Security.Cryptography.AesManaged
            $AesProvider.KeySize        = 256
            $AesProvider.BlockSize      = 128
            $AesProvider.Mode           = [System.Security.Cryptography.CipherMode]::CBC
            [Byte[]]$LenKey             = New-Object Byte[] 4
            [Byte[]]$LenIV              = New-Object Byte[] 4

            If($Path.Split('.')[-1] -ne $FileExtension)
            {
                Write-Error 'The file to decrypt must be named *.encrypted.'
                return
            }

            Try
            {
                $FileStreamReader = New-Object System.IO.FileStream("$Path", [System.IO.FileMode]::Open)
            }
            Catch
            {
                Write-Error "Unable to open input file $path for reading."
                return
            }

            $FileStreamReader.Seek(0, [System.IO.SeekOrigin]::Begin)         | Out-Null
            $FileStreamReader.Seek(0, [System.IO.SeekOrigin]::Begin)         | Out-Null
            $FileStreamReader.Read($LenKey, 0, 3)                            | Out-Null
            $FileStreamReader.Seek(4, [System.IO.SeekOrigin]::Begin)         | Out-Null
            $FileStreamReader.Read($LenIV,  0, 3)                            | Out-Null
            [Int]$LKey            = [System.BitConverter]::ToInt32($LenKey, 0)
            [Int]$LIV             = [System.BitConverter]::ToInt32($LenIV,  0)
            [Int]$StartC          = $LKey + $LIV + 8
            [Int]$LenC            = [Int]$FileStreamReader.Length - $StartC
            [Byte[]]$KeyEncrypted = New-Object Byte[] $LKey
            [Byte[]]$IV           = New-Object Byte[] $LIV
            $FileStreamReader.Seek(8, [System.IO.SeekOrigin]::Begin)         | Out-Null
            $FileStreamReader.Read($KeyEncrypted, 0, $LKey)                  | Out-Null
            $FileStreamReader.Seek(8 + $LKey, [System.IO.SeekOrigin]::Begin) | Out-Null
            $FileStreamReader.Read($IV, 0, $LIV)                             | Out-Null
            [Byte[]]$KeyDecrypted = $cert.PrivateKey.Decrypt($KeyEncrypted, $false)
            $Transform = $AesProvider.CreateDecryptor($KeyDecrypted, $IV)
            Try
            {
                $FileStreamWriter = New-Object System.IO.FileStream("$($path -replace '\.encrypted')", [System.IO.FileMode]::Create)
            }
            Catch
            {
                Write-Error "Unable to open output file for writing.`r`n$($_.Message)"
                Return
            }
            [Int]$Count  = 0
            [Int]$Offset = 0
            [Int]$BlockSizeBytes = $AesProvider.BlockSize / 8
            [Byte[]]$Data = New-Object Byte[] $BlockSizeBytes
            $CryptoStream = New-Object System.Security.Cryptography.CryptoStream($FileStreamWriter, $Transform, [System.Security.Cryptography.CryptoStreamMode]::Write)
            Do
            {
                $Count   = $FileStreamReader.Read($Data, 0, $BlockSizeBytes)
                $Offset += $Count
                $CryptoStream.Write($Data, 0, $Count)
            }
            While ($Count -gt 0)
            $CryptoStream.FlushFinalBlock()

            return Get-Item "$($path -replace '\.encrypted')"
        }
        catch
        {
            Write-Error -ErrorRecord $_
            return
        }
        finally
        {
            if ($null -ne $CryptoStream) { $CryptoStream.Close() }
            if ($null -ne $FileStreamWriter) { $FileStreamWriter.Close() }
            if ($null -ne $FileStreamReader) { $FileStreamReader.Close() }
        }
    }
}



