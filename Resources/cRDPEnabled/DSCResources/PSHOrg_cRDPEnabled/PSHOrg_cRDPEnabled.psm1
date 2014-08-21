function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.Boolean]
		$Enabled,

		[System.Boolean]
        $NLARequired = $true,

		[System.Boolean]
        $EnableDefaultFirewallRule = $true
	)

	Write-Verbose "Starting Get operation"
	[Boolean]$CurrentRDPEnabled                 = (Get-CimInstance -Namespace root/cimv2/TerminalServices -ClassName Win32_TerminalServiceSetting -ErrorAction Stop).AllowTSConnections
    [Boolean]$CurrentNLARequired                = (Get-CimInstance -Namespace root/cimv2/TerminalServices -ClassName Win32_TSGeneralSetting -ErrorAction Stop).UserAuthenticationRequired
    [Boolean]$CurrentEnableDefaultFirewallRule  = $true
    $FirewallRules                              = Get-NetFirewallRule -DisplayName "Remote Desktop - User Mode (TCP-In)","Remote Desktop - User Mode (UDP-In)" -ErrorAction Stop

    if ($CurrentRDPEnabled) {
        foreach ($rule in $FirewallRules) {
            if ($rule.Enabled -ne "True") {
                $CurrentEnableDefaultFirewallRule = $false
                break
            }
        }
    }
    else { # We don't care about the result if RDP is not enabled
        $CurrentEnableDefaultFirewallRule = $false
    }

    @{
        Enabled                    = $CurrentRDPEnabled;
        NLARequired                = $CurrentNLARequired;
        EnableDefaultFirewallRule  = $CurrentEnableDefaultFirewallRule
     }

     Write-Verbose "Completed Get operation"
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.Boolean]
		$Enabled,

		[System.Boolean]
        $NLARequired = $true,

		[System.Boolean]
        $EnableDefaultFirewallRule = $true
	)

	Write-Verbose "Starting Set operation"
	Write-Debug "Calling Invoke-CimMethod on win32_TerminalServiceSetting"
    Switch ($Enabled)
      {
        $true {
            Write-Verbose 'Beginning operation to set RDP to enabled'

            try {
                Get-CimInstance -Namespace root\cimv2\TerminalServices -ClassName Win32_TerminalServiceSetting -ErrorAction Stop |
                Invoke-CimMethod -MethodName SetAllowTSConnections -Arguments @{AllowTSConnections=1} -ErrorAction Stop
            }
            catch {
                Write-Error "Error during Invoke-CimMethod. This might happen if you have a GPO that forces the RDP configuration on the server.`n$_"
            }
            
            Write-Verbose 'Completed Set RDP to enabled.'

            if ($EnableDefaultFirewallRule) {
                Write-Verbose "Beginning operation to enable default Remote Desktop firewall rules"
                Get-NetFirewallRule -DisplayName "Remote Desktop - User Mode (TCP-In)","Remote Desktop - User Mode (UDP-In)" -ErrorAction Stop | Enable-NetFirewallRule -ErrorAction Stop
                Write-Verbose 'Completed operation to enable default Remote Desktop firewall rules'
            }
          }
        $false {
            Write-Verbose 'Beginning operation to set RDP to disabled'

            try {
                Get-CimInstance -Namespace root\cimv2\TerminalServices -ClassName Win32_TerminalServiceSetting -ErrorAction Stop |
                Invoke-CimMethod -MethodName SetAllowTSConnections -Arguments @{AllowTSConnections=0;ModifyFirewallException=1} -ErrorAction Stop # ModifyFirewallException will close the 'Remote Desktop' group firewall rule, if it's enabled
            }
            catch {
                Write-Error "Error during Invoke-CimMethod. This might happen if you have a GPO that forces the RDP configuration on the server.`n$_"
            }

            Write-Verbose 'Completed Set RDP to disabled.'
          }
      }
      Write-Debug "Completed Invoke-CimMethod on win32_TerminalServiceSetting"

      Write-Debug "Calling Invoke-CimMethod on win32_TSGeneralSetting"
      
      Write-Verbose "Beginning operation to set NLA required to $NLARequired"
      Get-CimInstance -Class "win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices -Filter "TerminalName='RDP-tcp'" -ErrorAction Stop | 
      Invoke-CimMethod -MethodName SetUserAuthenticationRequired -Arguments @{UserAuthenticationRequired=[int]$NLARequired}
      
      Write-Debug "Completed Invoke-CimMethod on win32_TSGeneralSetting"

      Write-Verbose "Set operation complete"
    
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.Boolean]
		$Enabled,

		[System.Boolean]
        $NLARequired = $true,

		[System.Boolean]
        $EnableDefaultFirewallRule = $true
	)

	Write-Verbose "Beginning Test operation"
    [Boolean]$CurrentRDPEnabled  = (Get-CimInstance -Namespace root/cimv2/TerminalServices -ClassName Win32_TerminalServiceSetting -ErrorAction Stop).AllowTSConnections
    [Boolean]$CurrentNLARequired = (Get-CimInstance -Namespace root/cimv2/TerminalServices -ClassName Win32_TSGeneralSetting -Filter "TerminalName='RDP-tcp'" -ErrorAction Stop).UserAuthenticationRequired
    $fwRules                     = Get-NetFirewallRule -DisplayName "Remote Desktop - User Mode (TCP-In)","Remote Desktop - User Mode (UDP-In)" -ErrorAction Stop
        
    if ($CurrentRDPEnabled -ne $Enabled) {
        Write-Verbose ("Configuration mismatch for Enabled. Current value: {0}. Expected value: {1}" -f $CurrentRDPEnabled, $Enabled)
        return $false
    }

    if ($CurrentNLARequired -ne $NLARequired) {
        Write-Verbose ("Configuration mismatch for NLARequired. Current value: {0}. Expected value: {1}" -f $CurrentNLARequired, $NLARequired)
        return $false
    }

    if ($CurrentRDPEnabled -and $EnableDefaultFirewallRule) { # We don't care about the result if RDP is not enabled
        foreach ($rule in $fwRules) {
            if (($rule.Enabled -eq "True") -ne $true) {
                Write-Verbose ("Configuration mismatch for EnableDefaultFirewallRule. {0} is {1}. Expected {2}" -f $rule.DisplayName, $rule.Enabled, $EnableDefaultFirewallRule)
                return $false
            }
        }
    }

    Write-Verbose "Test operation complete without configuration mismatch"

    return $true
}

Export-ModuleMember -Function *-TargetResource