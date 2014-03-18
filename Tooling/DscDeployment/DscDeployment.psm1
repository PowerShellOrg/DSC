param 
(
    [string]
    $ConfigurationDataPath = (Join-path (split-path (split-path $PSScriptRoot)) "Configuration"),
    [string]
    $LocalCertificateThumbprint = "$((Get-DscLocalConfigurationManager).CertificateId)"
)

$LocalCertificatePath = "cert:\LocalMachine\My\$LocalCertificateThumbprint"
$ConfigurationData = @{ AllNodes = @(); SiteData = @{}; Services=@{}; Credentials = @{} }

. $PSScriptRoot\ConvertTo-EncryptedFile.ps1
. $PSScriptRoot\ConvertFrom-EncryptedFile.ps1

function Get-Hashtable
{
    # Path to PSD1 file to evaluate
    param (
        [parameter(
            Position = 0,
            ValueFromPipelineByPropertyName,
            Mandatory
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('FullName')]
        [string]
        $Path
    ) 
    process 
    {
        Write-Verbose "Loading data from $Path."
        invoke-expression "DATA { $(get-content -raw -path $path) }"
    }    
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
        [parameter(
            ValueFromPipeline,
            Mandatory
        )]
        [System.Collections.Hashtable]
        $PasswordHashtable
    )
    begin
    {
        $CredentialHashtable = @{}
    }
    Process 
    {                
        foreach ($key in $PasswordHashtable.Keys)
        {
            Write-Verbose "Creating new credential for $key"
            $CredentialHashtable.Add($key, (New-Credential -username $key -password $PasswordHashtable[$key]))
        }        
    }
    end 
    {
        $CredentialHashtable 
    }
}

function Get-AllNodesConfigurationData
{
    [cmdletbinding()]
    param ($Path, [switch]$Force)
    if (($script:ConfigurationData.AllNodes.Count -eq 0) -or ($Force))
    {  
        Write-Verbose "Processing AllNodes from $Path."
        $script:ConfigurationData.AllNodes = @()
        dir (join-path $Path 'AllNodes\*.psd1') | 
            Get-Hashtable | 
            foreach-object { 
                Write-Verbose "Adding Name: $($_.Name)"
                $script:ConfigurationData.AllNodes += $_ 
            }
    }
}

function Get-SiteDataConfigurationData
{
    [cmdletbinding()]
    param ($Path, [switch]$Force)
    if (($script:ConfigurationData.SiteData.Keys.Count -eq 0) -or ($Force))
    { 
        Write-Verbose "Processing SiteData from $Path." 
        foreach ( $item in (dir (join-path $Path 'SiteData\*.psd1')) )
        {
            Write-Verbose "Loading data for site $($item.basename) from $($item.fullname)."
            $script:ConfigurationData.SiteData.Add($item.BaseName, (Get-Hashtable $item.FullName))
        }
    }
}

function Get-ServiceConfigurationData
{
    [cmdletbinding()]
    param ($Path, [switch]$Force)
    if (($script:ConfigurationData.Services.Keys.Count -eq 0) -or ($Force))
    { 
        Write-Verbose "Processing Services from $Path." 
        foreach ( $item in (dir (join-path $Path 'Services\*.psd1')) )
        {
            Write-Verbose "Loading data for site $($item.basename) from $($item.fullname)."
            $script:ConfigurationData.Services.Add($item.BaseName, (Get-Hashtable $item.FullName))
        }
    }
}

function Get-CredentialConfigurationData
{
    [cmdletbinding()]
    param ($Path, [switch]$Force)
    if (($script:ConfigurationData.Credentials.Keys.Count -eq 0) -or ($Force))
    { 
        Write-Verbose "Processing Credentials from $Path."
        foreach ( $item in (dir (join-path $Path 'Credentials\*.psd1.encrypted')) )
        {
            $script:ConfigurationData.Credentials = dir (join-path $Path 'Credentials\*.psd1.encrypted') | 
                Get-EncryptedPassword -StoreName {$_.Name -replace '\.encrypted' -replace '\.psd1'} |
                ConvertTo-CredentialLookup
        }
    }
}

function Get-ConfigurationData
{
    [cmdletbinding(DefaultParameterSetName='NoFilter')]
    param (
        [parameter()]
        [string]
        $Path = $ConfigurationDataPath,
        [parameter(
            ParameterSetName = 'NameFilter'
        )]
        [string]
        $Name,
        [parameter(
            ParameterSetName = 'NodeNameFilter'  
        )]
        [string]
        $NodeName,
        [parameter(
            ParameterSetName = 'RoleFilter'  
        )]
        [string]
        $Role, 
        [parameter()]
        [switch]
        $Force
    )             


    Get-AllNodesConfigurationData -Path $path 

    $ofs = ', '
    $FilteredResults = $true
    Write-Verbose "Checking for filters of AllNodes."
    switch ($PSCmdlet.ParameterSetName)
    {
        'Name'  {            
            Write-Verbose "Filtering for nodes with the Name $Name"
            $script:ConfigurationData.AllNodes = $script:ConfigurationData.AllNodes.Where({$_.Name -like $Name})
        }

        'NodeName' {            
            Write-Verbose "Filtering for nodes with the GUID of $NodeName"
            $script:ConfigurationData.AllNodes = $script:ConfigurationData.AllNodes.Where({$_.NodeName -like $NodeName})
        }
        'Role'  {
            Write-Verbose "Filtering for nodes with the Role of $Role"
            $script:ConfigurationData.AllNodes = $script:ConfigurationData.AllNodes.Where({ $_.roles -contains $Role})
        }
        default {
            Write-Verbose "Loading Site Data"
            Get-SiteDataConfigurationData -Path $path -Force:$Force
            Write-Verbose "Loading Services Data"
            Get-ServiceConfigurationData -Path $path -Force:$Force
            Write-Verbose "Loading Credential Data"
            Get-CredentialConfigurationData -Path $path -Force:$Force
        }
    }
    
    return $script:ConfigurationData
}

function Add-EncryptedPassword
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
    
    '@{' | Out-File $FilePath 
    foreach ($key in $Credentials.Keys)
    {
        Write-Verbose "Persisting credentials for $key to disk."
        "'$key' = '$($Credentials[$key])'" | Out-File $FilePath -Append
    }
    '}' | Out-File $FilePath -Append

    Write-Verbose "Encrypting credentials."
    ConvertTo-EncryptedFile -Path $FilePath -CertificatePath $LocalCertificatePath
    Remove-PlainTextPassword $FilePath
}

function Test-LocalCertificate
{
    param ()
    if (-not [string]::IsNullOrEmpty($LocalCertificateThumbprint))
    {        
        Write-Verbose "LocalCertificateThumbprint is present."
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
        Write-Warning "No local certificate supplied or configured with the DSC Local Configuration Manager."
        return $false
    }
}

function Get-EncryptedPassword
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
        $Path = (Join-path $ConfigurationDataPath 'Credentials'), 
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
    process
    {
        if (Test-LocalCertificate)
        {
            if (-not $PSBoundParameters.ContainsKey('EncryptedFilePath'))
            {
                $EncryptedFilePath = Join-Path $Path "$StoreName.psd1.encrypted"
            }

            Write-Verbose "Decrypting $EncryptedFilePath."
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
. $PSScriptRoot\Update-ModuleMetadataVersion.ps1
