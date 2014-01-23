param 
(
    [string]
    $ConfigurationDataPath = "$PSScriptRoot\Configuration",
    [string]
    $LocalCertificateThumbprint = "$((Get-DscLocalConfigurationManager).CertificateId)"
)

$LocalCertificatePath = "cert:\LocalMachine\My\$LocalCertificateThumbprint"

. $PSScriptRoot\ConvertTo-EncryptedFile.ps1
. $PSScriptRoot\ConvertFrom-EncryptedFile.ps1

function Get-Hashtable
{
    param ($path) 
    invoke-expression "DATA { @{$(get-content -raw -path $path)} }"
}

function New-Credential
{
    param ($username, $password)
    $securepassword = $password | ConvertTo-SecureString -AsPlainText -Force
    return (New-Object System.Management.Automation.PSCredential -ArgumentList $username, $securepassword)
}

function ConvertTo-CredentialLookup
{
    param (
        [System.Collections.Hashtable]
        $PasswordHashtable
    )

    $CredentialHashtable = @{}
    foreach ($key in $PasswordHashtable.Keys)
    {
        $CredentialHashtable.Add($key, (New-Credential -username $key -password $PasswordHashtable[$key]))
    }
    return $CredentialHashtable
}

function Get-ConfigurationData
{
    param (
        [parameter()]
        [string]
        $Path = $ConfigurationDataPath,
        [parameter()]
        [string]
        $Name,
        [parameter()]
        [string]
        $NodeName,
        [parameter()]
        [string]
        $Role
    )
    $ConfigurationData = @{}
    $ConfigurationData.AllNodes = @()
    $ConfigurationData.SiteData = @{}
    $ConfigurationData.Credentials = @{}
    
    $ConfigurationSiteDataPath = join-path $Path '\SiteData\*.psd1'
    $ConfigurationNodeDataPath = join-path $Path '\AllNodes\*.psd1'
    $ConfigurationCredentialDataPath = join-path $Path '\Credentials\*.psd1.encrypted'

    Write-Verbose "Processing AllNodes from $ConfigurationNodeDataPath."
    foreach ($datafile in (dir $ConfigurationNodeDataPath))
    {
        Write-Verbose "Loading $($datafile.BaseName) into ConfigurationData.AllNodes."
        $ConfigurationData.AllNodes += (Get-Hashtable $datafile.FullName)
    }

    if ((-not $PSBoundParameters.ContainsKey('Name')) -and
            (-not $PSBoundParameters.ContainsKey('NodeName')) -and
            (-not $PSBoundParameters.ContainsKey('Role')) 
        )
    {       
        Write-Verbose "Processing SiteData from $ConfigurationSiteDataPath."
        foreach ($datafile in (dir $ConfigurationSiteDataPath))
        {
            Write-Verbose "Loading $($datafile.BaseName) into ConfigurationData.SiteData."
            $ConfigurationData.SiteData.Add($datafile.BaseName, ((Get-Hashtable $datafile.FullName)))
        }        

        Write-Verbose "Processing Credentials from $ConfigurationCredentialDataPath."
        foreach ($datafile in (dir $ConfigurationCredentialDataPath))
        {
        
            $StoreName = ($datafile.Name -replace '\.encrypted' -replace '\.psd1')
            Write-Verbose "Decrypting Credential Store $StoreName from $($datafile.Name)."
            $DecryptedPasswordHash = Get-EncryptedPassword -StoreName $StoreName -Path $datafile.Directory
            Write-Verbose "Converting the saved usernames and passwords to credentials."
            $CredentialHashTable = ConvertTo-CredentialLookup $DecryptedPasswordHash
            Write-Verbose "Loading Credentials from $Storename into ConfigurationData.Credentials."
            $ConfigurationData.Credentials += $CredentialHashTable
        }
    }
    else
    {
        $ofs = ', '
        Write-Verbose "Filtering AllNodes."
        if ($PSBoundParameters.ContainsKey('Name'))
        {
            Write-Verbose "Filtering for nodes with the Name $Name"
            $ConfigurationData.AllNodes = $ConfigurationData.AllNodes.Where({$_.Name -like $Name})
        }
        if ($PSBoundParameters.ContainsKey('NodeName'))
        {
            Write-Verbose "Filtering for nodes with the GUID of $NodeName"
            $ConfigurationData.AllNodes = $ConfigurationData.AllNodes.Where({$_.NodeName -like $NodeName})
        }
        if ($PSBoundParameters.ContainsKey('Role'))
        {
            Write-Verbose "Filtering for nodes with the Role of $Role"
            $ConfigurationData.AllNodes = $ConfigurationData.AllNodes.Where({ $_.roles -contains $Role})
        }
    }
    
    return $ConfigurationData
}

function Add-EncyptedPassword
{
    param (                
        [parameter(mandatory)]
        [string]
        $StoreName,
        [parameter()]
        [string]
        $Path = (Join-path $ConfigurationDataPath 'Credentials'), 
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
        $Credentials += Get-EncryptedPassword -StoreName $StoreName -Path $Path
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
    
    foreach ($key in $Credentials.Keys)
    {
        Write-Verbose "Persisting credentials for $key to disk."
        "'$key' = '$($Credentials[$key])'" | Out-File $FilePath -Append
    }
    Write-Verbose "Encrypting credentials."
    ConvertTo-EncryptedFile -Path $FilePath -CertificatePath $LocalCertificatePath
    Remove-PlainTextPassword $FilePath
}

function Get-EncryptedPassword
{
    param (
        [parameter(mandatory)]
        [string]
        $StoreName,
        [parameter()]
        [string]
        $Path = (Join-path $ConfigurationDataPath 'Credentials'), 
        [parameter()]
        [string]
        $UserName
    )

    $EncryptedFilePath = Join-Path $Path "$StoreName.psd1.encrypted"

    Write-Verbose "Decrypting $Path."
    $DecryptedDataFile = ConvertFrom-EncryptedFile -path $EncryptedFilePath -CertificatePath $LocalCertificatePath
    Write-Verbose "Loading $($DecryptedDataFile.BaseName) into Credentials."
    $Credentials = (Get-Hashtable $DecryptedDataFile.FullName)
    Remove-PlainTextPassword $DecryptedDataFile.FullName
    if ($PSBoundParameters.ContainsKey('UserName'))
    {
        $CredentialsToReturn = @{}
        foreach ($User in $UserName)
        {
            $CredentialsToReturn.Add($User,$Credentials[$User])
        }
        return $CredentialsToReturn
    }
    else
    {
        return $Credentials
    }
    

}

function Remove-PlainTextPassword
{
    param (
        [parameter()]
        [string]
        $path
    )

    Start-Sleep -seconds 2
    Write-Verbose "Removing plain text credentials from $path"
    Remove-Item $path -Confirm:$false -Force

}



. $PSScriptRoot\Where-DscResource.ps1
. $PSScriptRoot\New-DscChecksumFile.ps1
. $PSScriptRoot\Get-DscResourceVersion.ps1
. $PSScriptRoot\New-DscZipFile.ps1
. $PSScriptRoot\Publish-DscResource.ps1


. $PSScriptRoot\Invoke-DscPull.ps1
. $PSScriptRoot\Get-DscEventLog.ps1
. $PSScriptRoot\Clear-DscEventLog.ps1

. $PSScriptRoot\Set-DscClient.ps1

