param 
(
    [string]
    $ConfigurationDataPath,
    [string]
    $LocalCertificateThumbprint = "$((Get-DscLocalConfigurationManager).CertificateId)"
)


$LocalCertificatePath = "cert:\LocalMachine\My\$LocalCertificateThumbprint"
$ConfigurationData = @{AllNodes=@(); Credentials=@{}; Applications=@{}; Services=@{}; SiteData =@{}}

. $psscriptroot\Get-Hashtable.ps1
. $psscriptroot\Test-LocalCertificate.ps1
. $psscriptroot\Add-NodeRoleFromServiceConfigurationData.ps1

. $psscriptroot\New-ConfigurationDataStore
. $psscriptroot\New-DscNodeMetadata.ps1

. $psscriptroot\Get-AllNodesConfigurationData.ps1
. $psscriptroot\Get-ConfigurationData.ps1
. $psscriptroot\Get-CredentialConfigurationData.ps1
. $psscriptroot\Get-ApplicationConfigurationData.ps1
. $psscriptroot\Get-ServiceConfigurationData.ps1
. $psscriptroot\Get-SiteDataConfigurationData.ps1
. $psscriptroot\Get-EncryptedPassword.ps1

. $psscriptroot\Add-EncryptedPassword.ps1
. $psscriptroot\ConvertFrom-EncryptedFile.ps1
. $psscriptroot\ConvertTo-CredentialLookup.ps1
. $psscriptroot\ConvertTo-EncryptedFile.ps1
. $psscriptroot\New-Credential.ps1
. $psscriptroot\Remove-PlainTextPassword.ps1


function Set-DscConfigurationDataPath {
    param (
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )

    $script:ConfigurationDataPath = (Resolve-path $Path).Path
}
Set-Alias -Name 'Set-ConfigurationDataPath' -Value 'Set-DscConfigurationDataPath'

function Get-DscConfigurationDataPath {    

    $script:ConfigurationDataPath
}
Set-Alias -Name 'Get-ConfigurationDataPath' -Value 'Get-DscConfigurationDataPath'

function Resolve-DscConfigurationDataPath {
    param (
        [parameter()]
        [string]
        $Path
    )

    if ( -not ($psboundparameters.containskey('Path')) ) {
        if ([string]::isnullorempty($script:ConfigurationDataPath)) {
            if (test-path $env:ConfigurationDataPath) {
                $path = $env:ConfigurationDataPath    
            }            
        }
        else {
            $path = $script:ConfigurationDataPath
        }        
    }

    if ( -not ([string]::isnullorempty($path)) ) {
        Set-DscConfigurationDataPath -path $path
    } 
   
}
Set-Alias -Name 'Resolve-ConfigurationDataPath' -Value 'Resolve-DscConfigurationDataPath'