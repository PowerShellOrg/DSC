function Enable-DscEventLog
{
    <#
        .SYNOPSIS
        Sets any DSC Event log (Operational, analytic, debug )

        .DESCRIPTION
        This cmdlet will set a DSC log when run with Enable-DscEventLog <channel Name>.

        .PARAMETER Channel
        Name of the channel of the event log to be set.

        .EXAMPLE
        C:\PS> Enable-DscEventLog "Analytic"
        C:\PS> Enable-DscEventLog -Channel "Debug"
    #>

    [CmdletBinding()]
    param
    (
        [ValidateSet("Debug", "Analytic", "Operational")]
        [string] $Channel = "Analytic",

        [string] $ComputerName = $env:ComputerName,
        [PSCredential] $Credential
    )

    $LogName = "Microsoft-Windows-Dsc"

    $eventLogFullName = "$LogName/$Channel"

    try
    {
        Write-Verbose "Enabling the log $eventLogFullName"
        if($ComputerName -eq $env:COMPUTERNAME)
        {
            wevtutil set-log $eventLogFullName /e:true /q:true
        }
        else
        {
            # For any other computer, invoke command.
            $scriptTosetChannel = [Scriptblock]::Create(" wevtutil set-log $eventLogFullName /e:true /q:true")

            if($Script:ThisCredential)
            {
                Invoke-Command -ScriptBlock $scriptTosetChannel -ComputerName $ComputerName -Credential $Credential
            }
            else
            {
                Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptTosetChannel
            }
        }

        Write-Verbose "The $Channel event log has been Enabled. "
    }
    catch
    {
        Write-Error "Error : $_ "
    }
}