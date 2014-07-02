Function ConvertTo-EncryptedFile
{
    [cmdletbinding(DefaultParameterSetName='LocalCertStoreAndFilePath')]
    Param(
        #Path to the file to encrypt.
        [Parameter(
            Position=0,
            Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'LocalCertStoreAndFilePath'
        )]
        [Parameter(
            Position=0,
            Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ArbitraryCertAndFilePath'
        )]
        [string]
        $Path,

        #FileInfo object to encrypt.
        [Parameter(
            Position=0,
            ValueFromPipeline=$true,
            ParameterSetName = 'LocalCertStoreAndInputObject'
        )]
        [Parameter(
            Position=0,
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
    
    process    
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'LocalCertStoreAndFilePath' { Write-Verbose "Loading certificate from $CertificatePath"; $Certificate = Get-Item $CertificatePath }
            'LocalCertStoreAndInputObject' { Write-Verbose "Loading certificate from $CertificatePath"; $Certificate = Get-Item $CertificatePath ; $Path = $InputObject.FullName }
            'ArbitraryCertAndInputObject' { $Path = $InputObject.FullName }
            'ArbitraryCertAndFilePath' {  }
        }
        try
        {
            $Path = (Resolve-Path $Path -ErrorAction Stop).ProviderPath        

            $AesProvider                = New-Object System.Security.Cryptography.AesManaged
            $AesProvider.KeySize        = 256
            $AesProvider.BlockSize      = 128
            $AesProvider.Mode           = [System.Security.Cryptography.CipherMode]::CBC

            $KeyFormatter               = New-Object System.Security.Cryptography.RSAPKCS1KeyExchangeFormatter($Certificate.PublicKey.Key)
            [Byte[]]$KeyEncrypted       = $KeyFormatter.CreateKeyExchange($AesProvider.Key, $AesProvider.GetType())
            [Byte[]]$LenKey             = $Null
            [Byte[]]$LenIV              = $Null
            [Int]$LKey                  = $KeyEncrypted.Length
            $LenKey                     = [System.BitConverter]::GetBytes($LKey)
            [Int]$LIV                   = $AesProvider.IV.Length
            $LenIV                      = [System.BitConverter]::GetBytes($LIV)
    
            $FileStreamWriter = $Null
            Try 
            { 
                $FileStreamWriter = New-Object System.IO.FileStream("$Path.$FileExtension", [System.IO.FileMode]::Create) 
            }
            Catch 
            {
                $message = "Unable to open output file ($Path.$FileExtension) for writing."
                throw $message
            }
    
            $FileStreamWriter.Write($LenKey,         0, 4)
            $FileStreamWriter.Write($LenIV,          0, 4)
            $FileStreamWriter.Write($KeyEncrypted,   0, $LKey)
            $FileStreamWriter.Write($AesProvider.IV, 0, $LIV)

            $Transform                  = $AesProvider.CreateEncryptor()
            $CryptoStream               = New-Object System.Security.Cryptography.CryptoStream($FileStreamWriter, $Transform, [System.Security.Cryptography.CryptoStreamMode]::Write)
            [Int]$Count                 = 0
            [Int]$Offset                = 0
            [Int]$BlockSizeBytes        = $AesProvider.BlockSize / 8
    
            [Byte[]]$Data               = New-Object Byte[] $BlockSizeBytes
            [Int]$BytesRead             = 0
    
            Try 
            { 
                $FileStreamReader     = New-Object System.IO.FileStream("$Path", [System.IO.FileMode]::Open)    
            }
            Catch 
            { 
                throw "Unable to open input file ($Path) for reading."
            }

            Do
            {
                $Count   = $FileStreamReader.Read($Data, 0, $BlockSizeBytes)
                $Offset += $Count
                $CryptoStream.Write($Data, 0, $Count)
                $BytesRead += $BlockSizeBytes
            } While ($Count -gt 0)

            $CryptoStream.FlushFinalBlock()
        }
        catch 
        {
            throw $_
        }
        finally
        {            
            $CryptoStream.Close()
            $FileStreamReader.Close()
            $FileStreamWriter.Close()
        }
    }
}


