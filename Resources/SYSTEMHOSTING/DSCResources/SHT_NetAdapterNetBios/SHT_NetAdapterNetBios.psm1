<### 
 # SHT_DnsClient - A DSC resource for modifying the IPv4 Dns Client settings on a network adapter.
 # Authored by: M.T.Nielsen - mni@systemhosting.dk
 #>

function Get-TargetResource
{
    [CmdletBinding()]
	param
	(		
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
        [string]$InterfaceAlias
	)
	
    Write-Verbose "Get-TargetResource - InterfaceAlias: $InterfaceAlias"

    $configuration = GetNetworkAdapterConfiguration -InterfaceAlias $InterfaceAlias
    
    switch($configuration.TcpipNetbiosOptions) {
        0 { $netBios = 'Default' }
        1 { $netBios = 'Enabled' }
        2 { $netBios = 'Disabled' }
    }

    Write-Output @{
        InterfaceAlias = $InterfaceAlias
        NetBIOS = $netBios
    }
}


function Set-TargetResource
{
    [CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
        [string]$InterfaceAlias,

        [Parameter(Mandatory)]
        [ValidateSet('Default','Enabled','Disabled')]
        [string]$NetBios
	)

    Write-Verbose "Set-TargetResource"

    $configuration = GetNetworkAdapterConfiguration -InterfaceAlias $InterfaceAlias

    switch($NetBios) {
        "Default" { $option = 0 }
        "Enabled" { $option = 1 }
        "Disabled" { $option = 2 }
    }

    Write-Verbose ('Setting NetBios configuration to {0}' -f $option)
    [void]$configuration.SetTcpipNetbios($option)
}


function Test-TargetResource
{
    [CmdletBinding()]
    param
	(		
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$InterfaceAlias,

        [Parameter(Mandatory)]
        [ValidateSet('Default','Enabled','Disabled')]
        [string]$NetBios
	)

    Write-Verbose "Test-TargetResource"

    $configuration = GetNetworkAdapterConfiguration -InterfaceAlias $InterfaceAlias

    switch($configuration.TcpipNetbiosOptions) {
        0 { $returnValue = $NetBios -eq 'Default' }
        1 { $returnValue = $NetBios -eq 'Enabled' }
        2 { $returnValue = $NetBios -eq 'Disabled' }
    }

    if(-not $returnValue) {
        Write-Verbose ('Configuration mismatch on NetBios setting. Current setting: {0}. Expected setting: {1}' -f $configuration.TcpipNetbiosOptions, $NetBios)
    }

    return $returnValue
}


function GetNetworkAdapterConfiguration {
    [Cmdletbinding()]
    param(
        [string]$InterfaceAlias
    )

    $adapter = Get-WmiObject -Query ('SELECT GUID,NetConnectionID FROM Win32_NetworkAdapter WHERE NetConnectionID = "{0}"' -f $InterfaceAlias)
    if($adapter.NetConnectionID -ne $InterfaceAlias) { throw "Adapter NetConnectionID does not match $InterfaceAlias" }

    $wmiObject = Get-WmiObject -Query ('SELECT * FROM Win32_NetworkAdapterConfiguration WHERE SettingID = "{0}"' -f $adapter.GUID)
    if($wmiObject.SettingID -ne $adapter.GUID) { throw ('Configuration GUID does not match SettingID {0}' -f $adapter.GUID) }

    return $wmiObject
}



#  FUNCTIONS TO BE EXPORTED 
Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource