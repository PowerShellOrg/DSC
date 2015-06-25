function Get-DscConfigurationData
{
    [cmdletbinding(DefaultParameterSetName='NoFilter')]
    param (
        [parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $Path,

        [ValidateNotNullOrEmpty()]
        [string] $CertificateThumbprint,

        [parameter(ParameterSetName = 'NameFilter')]
        [string] $Name,

        [parameter(ParameterSetName = 'NodeNameFilter')]
        [string] $NodeName,

        [parameter()]
        [switch] $Force
    )

    begin {

        if (($script:ConfigurationData -eq $null) -or $force) {
            $script:ConfigurationData = @{ AllNodes = @(); SiteData = @{}; Applications = @{}; Services=@{}; Credentials = @{} }
        }

        $ResolveConfigurationDataPathParams = @{}
        if ($psboundparameters.containskey('path')) {
            $ResolveConfigurationDataPathParams.Path = $path
        }
        Resolve-ConfigurationDataPath @ResolveConfigurationDataPathParams

        if ($CertificateThumbprint)
        {
            Set-DscConfigurationCertificate -CertificateThumbprint $CertificateThumbprint
        }
    }
    end {

        Get-AllNodesConfigurationData

        Write-Verbose 'Checking for filters of AllNodes.'
        switch ($PSCmdlet.ParameterSetName)
        {
            'NameFilter' {
                Write-Verbose "Filtering for nodes with the Name $Name"
                $script:ConfigurationData.AllNodes = $script:ConfigurationData.AllNodes.Where({$_.Name -like $Name})
            }
            'NodeNameFilter' {
                Write-Verbose "Filtering for nodes with the GUID of $NodeName"
                $script:ConfigurationData.AllNodes = $script:ConfigurationData.AllNodes.Where({$_.NodeName -like $NodeName})
            }
            default {
            }
        }
        Write-Verbose 'Loading Site Data'
        Get-SiteDataConfigurationData
        Write-Verbose 'Loading Services Data'
        Get-ServiceConfigurationData
        Write-Verbose 'Loading Credential Data'
        Get-CredentialConfigurationData

        return $script:ConfigurationData
    }
}

Set-Alias -Name 'Get-ConfigurationData' -Value 'Get-DscConfigurationData'
