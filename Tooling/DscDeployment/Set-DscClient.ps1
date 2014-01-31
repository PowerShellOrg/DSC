function Set-DscClient
{
    param (
        [parameter(
            ValueFromPipelineByPropertyName
        )]
        [string]
        $Name, 
        [parameter(
            ValueFromPipelineByPropertyName
        )]
        [System.Management.Automation.Runspaces.PSSession]
        $Session, 
        [parameter(
            ValueFromPipelineByPropertyName
        )]
        [string]
        $NodeName, 
        [parameter()]
        [switch]
        $ClearConfigurationOnly, 
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
            Get-Process -Name WmiPrvSE -ErrorAction SilentlyContinue | 
                Stop-Process -Force     
        }
        
        if (-not $ClearConfigurationOnly)
        {
            if (-not $PSBoundParameters.ContainsKey($NodeName))
            {
                $Node = ($ConfigurationData.AllNodes | 
                    Where-Object { $_.Name -like $Name })
                $NodeName =  $Node.NodeName
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
                PullClientConfig -NodeId $NodeName -NodeName $Name -PullServer $ConfigurationData['SiteData'][$Node.Location]['PullServer'] | 
                    Out-Null
            
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
