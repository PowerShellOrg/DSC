function Invoke-DscPull
{
    param (
        $CimSession = $null,
        $Flag = 3
        )
    $parameters = @{        
        Namespace = 'root/microsoft/windows/desiredstateconfiguration'
        Class  = 'MSFT_DscLocalConfigurationManager'
        MethodName = 'PerformRequiredConfigurationChecks'
        Arguments = @{Flags=[uint32]$flag} 
        Verbose = $true
        ErrorAction = 'Stop'
    }
    if ($CimSession)
    {
        $parameters.CimSession =  $CimSession
    }
    Invoke-CimMethod @parameters 
}
