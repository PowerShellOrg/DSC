function Invoke-DscPull
{
    <#
        .Synopsis
            Forces a consistency check on a targeted server.
        .Description
            Forces a consistency check on a targeted server.  The LCM will run local consistency checks.  
            In order to force the LCM to pull a new configuration, you many need to run this command multiple times, 
            as the configuration will pull from the pull server on every "x" local check (where the minimum number of checks is 2).
        .Example
            Invoke-DscPull -ComputerName OR-WEB01 -Verbose
        .Example
            1..7 | Invoke-DscPull -ComputerName {"or-web0$_"} 
        .Example
            Invoke-DscPull -Computer OR-WEB01 -Verbose -Force            
        .Example
            Invoke-DscPull OR-WEB01 -verbose
            
    #>
    param (
        #
        [parameter(ValueFromPipeline=$true, Position=0)]
        [alias('ComputerName', 'Name', '__Server')]
        $CimSession = $null,
        [switch]
        $Force
        )
    Begin {
        $Flag = 3
        if ($PSBoundParameters.ContainsKey('Flag')) {
            $PSBoundParameters.Remove('Flag') | Out-Null
    }
        if ($PSBoundParameters.ContainsKey('Force')) {
            $PSBoundParameters.Remove('Force') | Out-Null
        }
    }
    Process {

    if ($Force)
    {
            Write-Verbose ""
            Write-Verbose "Terminating any existing WmiPrvSE processes to make sure that there are no cached resources mucking about."
        Get-CimInstance -ClassName Win32_Process -Filter 'Name like "WmiPrvSE.exe"' @parameters | 
            Invoke-CimMethod -MethodName 'Terminate' | 
            Out-Null
    }

        $parameters = @{        
        Namespace = 'root/microsoft/windows/desiredstateconfiguration'
        Class  = 'MSFT_DscLocalConfigurationManager'
        MethodName = 'PerformRequiredConfigurationChecks'
        Arguments = @{Flags=[uint32]$flag} 
    }
    
        Write-Verbose ""
        Write-Verbose "Forcing a consistency check on $CimSession"
        Invoke-CimMethod @parameters @PSBoundParameters
    }
}


