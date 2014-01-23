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
            Invoke-CimMethod -MethodName 'Terminate'
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