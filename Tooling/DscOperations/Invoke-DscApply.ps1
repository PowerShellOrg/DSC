function Invoke-DscApply
{
    <#
        .Synopsis
            Uses the Configuration Agent to apply the configuration that is pending.
        .Description
            Uses the Configuration Agent to apply the configuration that is pending.  
            If there is no configuration pending, this method reapplies the current configuration.
        .Example
            Invoke-DscApply -CimSession SERVER01 -Verbose
        .Example
            1..7 | Invoke-DscApply -CimSession {"SERVER0$_"} 
            
    #>
    param (
        [parameter(ValueFromPipeline=$true, Position=0)]
        [alias('ComputerName', 'Name', '__Server')]
        $CimSession = $null
        )
    
    Process {

        $parameters = @{        
        Namespace = 'root/microsoft/windows/desiredstateconfiguration'
        Class  = 'MSFT_DscLocalConfigurationManager'
        MethodName = 'ApplyConfiguration'
        }
    
        Write-Verbose ""
        Write-Verbose "Forcing an application of configuration on $CimSession"
        Invoke-CimMethod @parameters @PSBoundParameters
    }
}


