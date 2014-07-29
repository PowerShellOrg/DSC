function Set-DscClient
{
    <#
        .Synopsis
            Configures the Local Configuration Manager (LCM) for a server
        .Description
            Configures the Local Configuration Manager (LCM) for a server.  Parameters can either be specified manually or looked up from configuration data.
        .Example
            Set-DscClient -Name OR-WEB01 -ConfigurationData (Get-DscConfigurationData -path d:\gitlab\Dsc_Configuration)
    #>
    [cmdletbinding(DefaultParameterSetName='FromCommandLine')]
    param (
        #Name of the host to configure.  If you are using -ConfigurationData, this will need to be the host name as specified in the Name property.
        [parameter(
            Position = 0,
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [alias('ComputerName', 'PSComputerName', '__Server')]
        [string]
        $Name, 

        #NodeName is what will be set for the ConfigurationID on the LCM.
        [parameter(
            Position = 1,
            ValueFromPipelineByPropertyName,
            Mandatory,
            ParameterSetName = 'FromCommandLine'
        )]
        [string]
        $NodeName, 

        #The url for the Pull Server to contact for configurations.
        [parameter(
            Position = 2,
            ValueFromPipelineByPropertyName,
            Mandatory,
            ParameterSetName = 'FromCommandLine'
        )]
        [string]
        $PullServerUrl,

        #The thumbprint for the certificate the LCM should use to decrypt passed credentials.
        [parameter(
            Position = 3,
            ValueFromPipelineByPropertyName,
            Mandatory,
            ParameterSetName = 'FromCommandLine'
        )]
        [string]
        $CertificateThumbprint,

        #Setting this flag will just clear the existing LCM settings.
        [parameter(
            ParameterSetName = 'ClearConfigOnly'
        )]
        [switch]
        $ClearConfigurationOnly, 

        #The ConfigurationData hashtable (from Get-DscConfigurationData in the DscConfiguration module).
        [parameter(
            Position = 1,
            Mandatory,
            ParameterSetName = 'FromConfigurationData'
        )]
        [System.Collections.Hashtable]
        $ConfigurationData
    )
    
    process {
        
        if ($PSCmdlet.ParameterSetName -eq 'FromConfigurationData') {
            $Node = ($ConfigurationData.AllNodes | 
                Where-Object { $_.Name -like $Name })
            $NodeName =  $Node.NodeName
            $CertificateThumbprint = $ConfigurationData['AllNodes'].where({$_.NodeName -eq '*'}).CertificateID
            $PullServerUrl = Resolve-DscConfigurationProperty -ConfigurationData $ConfigurationData -Node $Node -PropertyName 'PullServer'
        }       

        $ICMParams = @{ 
            Session = New-PSSession -ComputerName $Name 
        }

        Write-Verbose 'Clearing out pending and current MOFs and existing LCM configuration.'
        icm @ICMParams -ScriptBlock {
            dir 'c:\windows\System32\configuration\*.mof*' | Remove-Item
            Get-Process -Name WmiPrvSE -ErrorAction SilentlyContinue | 
                Stop-Process -Force     
        }
        
        if (-not $ClearConfigurationOnly)
        {
            Write-Verbose ""
            Write-Verbose "$Name will be configured with: "
            Write-Verbose "`tNodeName = $NodeName"
            Write-Verbose "`tConfigurationID = $ConfigurationID"
            Write-Verbose "`tPullServerUrl = $PullServerUrl"
            Write-Verbose "`tCertificateID = $CertificateThumbprint"
            
                    
            configuration PullClientConfig
            {
                param ($NodeName, $ConfigurationID, $PullServer, $LocalCertificateThumbprint)    
                
                Node $NodeName
                {
                    LocalConfigurationManager
                    {
                        AllowModuleOverwrite = 'True'
                        CertificateID = $LocalCertificateThumbprint
                        ConfigurationID = $ConfigurationID
                        ConfigurationModeFrequencyMins = 60 
                        ConfigurationMode = 'ApplyAndAutoCorrect'
                        RebootNodeIfNeeded = 'True'
                        RefreshMode = 'PULL' 
                        DownloadManagerName = 'WebDownloadManager'
                        DownloadManagerCustomData = (@{ServerUrl = "http://$PullServer/psdscpullserver.svc";AllowUnsecureConnection = 'True'})
                    }
                }
            }

            if (-not [string]::IsNullOrEmpty($NodeName))
            {
                Write-Verbose "Generating Pull Client Configuration for $Name."                
                PullClientConfig -NodeName $Name -ConfigurationID $NodeName -PullServer $PullServerUrl -LocalCertificateThumbprint $CertificateThumbprint
                
                Write-Verbose "Applying Pull Client Configuration for $Name"
                Set-DSCLocalConfigurationManager -Path .\PullClientConfig -ComputerName $Name -Verbose
                Remove-Item ./pullclientconfig -Recurse -Force
            }
            else
            {
                Write-Verbose "No matching NodeName for $Name."
            }
            
        }        
    }
}


