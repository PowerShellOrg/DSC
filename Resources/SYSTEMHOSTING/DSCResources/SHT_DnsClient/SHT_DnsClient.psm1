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
    $properties = Get-DnsClient -InterfaceAlias $InterfaceAlias
    
    Write-Output @{
        InterfaceAlias = $properties.InterfaceAlias
        RegisterThisConnectionAddress = $properties.RegisterThisConnectionAddress
        UseSuffixWhenRegistering = $properties.UseSuffixWhenRegistering
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

        # Windows default values:
        [bool]$RegisterThisConnectionAddress = $true,
        [bool]$UseSuffixWhenRegistering = $false
	)

    Write-Verbose "Set-TargetResource - InterfaceAlias: $InterfaceAlias, RegisterThisConnectionAddress: $RegisterThisConnectionAddress, UseSuffixWhenRegistering: $UseSuffixWhenRegistering"

    Get-DnsClient -InterfaceAlias $InterfaceAlias | Set-DnsClient -UseSuffixWhenRegistering $UseSuffixWhenRegistering -RegisterThisConnectionsAddress $RegisterThisConnectionAddress
}


function Test-TargetResource
{
    [CmdletBinding()]
    param
	(		
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$InterfaceAlias,

        # Windows default values:
        [bool]$RegisterThisConnectionAddress = $true,
        [bool]$UseSuffixWhenRegistering = $false
	)

    Write-Verbose "Test-TargetResource - InterfaceAlias: $InterfaceAlias, RegisterThisConnectionAddress: $RegisterThisConnectionAddress, UseSuffixWhenRegistering: $UseSuffixWhenRegistering"

    $properties = Get-DnsClient -InterfaceAlias $InterfaceAlias

    if($properties.RegisterThisConnectionAddress -ne $RegisterThisConnectionAddress) {
        Write-Verbose ('Configuration mismatch in property RegisterThisConnectionAddress. Set value: {0}. Expected value: {1}.' -f $properties.RegisterThisConnectionAddress, $RegisterThisConnectionAddress)
        return $false
    }
    
    if($properties.UseSuffixWhenRegistering -ne $UseSuffixWhenRegistering) {
        Write-Verbose ('Configuration mismatch in property UseSuffixWhenRegistering. Set value: {0}. Expected value: {1}.' -f $properties.UseSuffixWhenRegistering, $UseSuffixWhenRegistering)
        return $false
    }
    
    return $true
}


Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource