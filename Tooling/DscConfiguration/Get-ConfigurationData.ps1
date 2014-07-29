function Get-DscConfigurationData
{
    [cmdletbinding(DefaultParameterSetName='NoFilter')]
    param (
        [parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,
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

    begin {

        if (($script:ConfigurationData -eq $null) -or $force) {
            $script:ConfigurationData = @{ AllNodes = @(); SiteData = @{}; Applications = @{}; Services=@{}; Credentials = @{} }
        }

        $ResolveConfigurationDataPathParams = @{}
        if ($psboundparameters.containskey('path')) {
            $ResolveConfigurationDataPathParams.Path = $path
        }
        Resolve-ConfigurationDataPath @ResolveConfigurationDataPathParams
        
    }
    end { 

        Get-AllNodesConfigurationData

        $ofs = ', '
        $FilteredResults = $true
        Write-Verbose 'Checking for filters of AllNodes.'
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
                Write-Verbose 'Loading Site Data'
                Get-SiteDataConfigurationData 
                Write-Verbose 'Loading Services Data'
                Get-ServiceConfigurationData 
                Write-Verbose 'Loading Credential Data'
                Get-CredentialConfigurationData 
                Write-Verbose 'Loading Application Data'
                Get-ApplicationConfigurationData 
            }
        }

        Add-NodeRoleFromServiceConfigurationData
        return $script:ConfigurationData
    }

    
}

Set-Alias -Name 'Get-ConfigurationData' -Value 'Get-DscConfigurationData'

