function Invoke-DscPull
{
    param (
        $CimSession = $null,
        $Flag = 3, 
        [switch]
        $Force
        )

    $parameters = @{}

    if ($CimSession)
    {
        $parameters.CimSession =  $CimSession
    }

    if ($Force)
    {
        Get-CimInstance -ClassName Win32_Process -Filter 'Name like "WmiPrvSE.exe"' @parameters | 
            Invoke-CimMethod -MethodName 'Terminate' | 
            Out-Null
        invoke-command $CimSession {
            if (test-path 'c:\program files\windowspowershell\modules\') {
                dir 'c:\program files\windowspowershell\modules\*' -directory | Remove-Item -rec -force
            }               
        }       
    }

    $parameters = $parameters + @{        
        Namespace = 'root/microsoft/windows/desiredstateconfiguration'
        Class  = 'MSFT_DscLocalConfigurationManager'
        MethodName = 'PerformRequiredConfigurationChecks'
        Arguments = @{Flags=[uint32]$flag} 
        Verbose = $true
        ErrorAction = 'Stop'
    }
    
    Invoke-CimMethod @parameters 
}


