function Clear-DSCEventLog
{  
    param ($session) 
    icm $session {
        function Clear-WinEvent
        {
            [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High',DefaultParameterSetName="LogName")]
    
            param(        
                [Parameter(
                    Position=0,
                    Mandatory=$true,
                    ParameterSetName="LogName",
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true
                )]
                [String[]]$LogName,        
    
                [Parameter(
                    Position=0,
                    Mandatory=$true,
                    ParameterSetName="EventLogConfiguration",
                    ValueFromPipeline=$true
                )]
                [System.Diagnostics.Eventing.Reader.EventLogConfiguration[]]$EventLog,
        
                [switch]$Force
        
            )    

    
            process
            {
                switch($PSCmdlet.ParameterSetName)
                {
                    'LogName' 
                    {
                        Write-Verbose "ParameterSetName=LogName"
                        foreach($l in $LogName)
                        {            
                            if($Force -or $PSCmdlet.ShouldProcess($env:COMPUTERNAME,"Clear Event log '$l'"))
                            {
                                [System.Diagnostics.Eventing.Reader.EventLogSession]::GlobalSession.ClearLog($l)
                            }                    
                        }
                    }
            
                    'EventLogConfiguration'
                    {                
                        Write-Verbose "ParameterSetName=EventLogConfiguration"
                        foreach($l in $EventLog)
                        {            
                            if($Force -or $PSCmdlet.ShouldProcess($env:COMPUTERNAME,"Clear Event log '$($l.LogName)'"))
                            {
                                [System.Diagnostics.Eventing.Reader.EventLogSession]::GlobalSession.ClearLog($l.LogName)
                            }                    
                        }                 
                
                    }
                }
            }
        }
        Get-WinEvent -ListLog Microsoft-Windows-DSC/Operational  -Force | 
            clear-winevent -force

    }    
}


