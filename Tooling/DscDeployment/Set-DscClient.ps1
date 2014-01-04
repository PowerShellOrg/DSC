function Set-DscClient
{
    param (
        [parameter(ValueFromPipelineByPropertyName)]
        [string]
        $Name, 
        [parameter(ValueFromPipelineByPropertyName)]
        [System.Management.Automation.Runspaces.PSSession]
        $Session, 
        [parameter(ValueFromPipelineByPropertyName)]
        [string]
        $NodeName, 
        [parameter()]
        [string]
        $TargetPullServer, 
        [parameter()]
        [switch]
        $SkipConfigure, 
        [parameter()]
        [System.Collections.Hashtable]
        $ConfigurationData = (Get-ConfigurationData)
    )

    process
    {
        
        if (-not $PSBoundParameters.ContainsKey('Session'))
        {
            Write-Verbose "Creating PSSession to $Name."
            $Session = New-PSSession -ComputerName $Name    
        }       

        $ICMParams = @{ 
            Session = $Session
        }

        Write-Verbose "Clearing out pending and current MOFs and existing LCM configuration."
        icm @ICMParams -ScriptBlock {
            dir "c:\windows\System32\configuration\*.mof*" | Remove-Item
            if (test-path "c:\program files\windowspowershell\modules\")
            {
                dir "c:\program files\windowspowershell\modules\" | Remove-Item -rec -force
            }            
        }
        
        if (-not $SkipConfigure)
        {
            if (-not $PSBoundParameters.ContainsKey($NodeName))
            {
                $NodeName = ($ConfigurationData.AllNodes | 
                    Where-Object { $_.Name -like $Name }).NodeName
                Write-Verbose "$Name will be configured with $NodeName."
            }
                       
            configuration PullClientConfig
            {
                param ($NodeName, $NodeId, $PullServer)    
                
                Node $NodeName
                {
                    LocalConfigurationManager
                    {
                        AllowModuleOverwrite = 'True'
                        CertificateID = $LocalCertificateThumbprint
                        ConfigurationID = $NodeId
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
                PullClientConfig -NodeId $NodeName -NodeName $Name -PullServer $TargetPullServer | Out-Null
            
                Set-DSCLocalConfigurationManager -Path .\PullClientConfig -ComputerName $Name -Verbose
            }
            else
            {
                Write-Verbose "No matching NodeName for $Name."
            }

        }
    }
}