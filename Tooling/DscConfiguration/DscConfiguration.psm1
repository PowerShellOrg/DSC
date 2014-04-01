param 
(
    [string]
    $ConfigurationDataPath = (Join-path (split-path (split-path $PSScriptRoot)) 'Configuration'),
    [string]
    $LocalCertificateThumbprint = "$((Get-DscLocalConfigurationManager).CertificateId)"
)

$LocalCertificatePath = "cert:\LocalMachine\My\$LocalCertificateThumbprint"
$ConfigurationData = $null

. $psscriptroot\Add-EncryptedPassword.ps1
. $psscriptroot\Add-NodeRoleFromServiceConfigurationData.ps1
. $psscriptroot\ConvertFrom-EncryptedFile.ps1
. $psscriptroot\ConvertTo-CredentialLookup.ps1
. $psscriptroot\ConvertTo-EncryptedFile.ps1
. $psscriptroot\Get-AllNodesConfigurationData.ps1
. $psscriptroot\Get-ConfigurationData.ps1
. $psscriptroot\Get-CredentialConfigurationData.ps1
. $psscriptroot\Get-DscResourceVersion.ps1
. $psscriptroot\Get-EncryptedPassword.ps1
. $psscriptroot\Get-Hashtable.ps1
. $psscriptroot\Get-ServiceConfigurationData.ps1
. $psscriptroot\Get-SiteDataConfigurationData.ps1
. $psscriptroot\New-Credential.ps1
. $psscriptroot\Remove-PlainTextPassword.ps1
. $psscriptroot\Resolve-ConfigurationProperty.ps1
. $psscriptroot\Test-LocalCertificate.ps1
. $psscriptroot\Update-ModuleMetadataVersion.ps1
. $psscriptroot\New-DscNodeMetadata.ps1


