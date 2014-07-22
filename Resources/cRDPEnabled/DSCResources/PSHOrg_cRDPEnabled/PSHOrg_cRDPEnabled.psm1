function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.Boolean]
		$Enabled
	)

	Write-Verbose "Checking Win32_TerminalServiceSetting."
	[boolean]$val = (Get-CimInstance -Namespace root/cimv2/TerminalServices -ClassName Win32_TerminalServiceSetting).AllowTSConnections
    @{Enabled = $val}
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.Boolean]
		$Enabled
	)

	Write-Verbose "Starting set operation."
	Write-Debug "Calling invoke-cimmethod on win32_TerminalServiceSetting."
    Switch ($Enabled)
      {
        $true {
            Write-Verbose 'Beginning operation to set RDP to enabled'
            Get-CimInstance -Namespace root\cimv2\TerminalServices -ClassName Win32_TerminalServiceSetting -ErrorAction Stop |
            Invoke-CimMethod -MethodName SetAllowTSConnections -Arguments @{AllowTSConnections=1}
            Write-Debug 'Completed Set RDP to enabled.'
          }
        $false {
            Write-Verbose 'Beginning operation to set RDP to disabled'
            Get-CimInstance -Namespace root\cimv2\TerminalServices -ClassName Win32_TerminalServiceSetting -ErrorAction Stop |
            Invoke-CimMethod -MethodName SetAllowTSConnections -Arguments @{AllowTSConnections=0}
            Write-Debug 'Completed Set RDP to disabled.'
          }
      }
    
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.Boolean]
		$Enabled
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."
	Write-Debug "Beginning test for RDPEnabled."
    [Boolean]$Set = (Get-CimInstance -Namespace root/cimv2/TerminalServices -ClassName Win32_TerminalServiceSetting).AllowTSConnections
    switch ($Enabled)
      {
        $true {
            switch ($Set)
              {
                $true {
                    Write-Verbose "RDP should be set to enabled and it is currently enabled"
                    return $true
                  }
                $false {
                    Write-Verbose "RDP should be set to enabled and it is currently disabled"
                    return $false
                  }
              }
          }
        $false {
            switch ($Set)
              {
                $true {
                    Write-Verbose "RDP should be set to disabled and it is currently enabled"
                    return $false
                  }
                $false {
                    Write-Verbose "RDP should be set to disabled and it is currently disabled"
                    return $true
                  }
              }
          }
      }
}

Export-ModuleMember -Function *-TargetResource
