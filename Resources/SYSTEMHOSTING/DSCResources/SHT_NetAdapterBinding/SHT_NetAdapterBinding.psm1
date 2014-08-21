<### 
 # SHT_DnsClient - A DSC resource for modifying network adapter bindings.
 # Authored by: M.T.Nielsen - mni@systemhosting.dk
 #>

function Get-TargetResource
{
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$InterfaceAlias,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$ComponentID
	)
	
    Write-Verbose "Get-TargetResource - InterfaceAlias: $InterfaceAlias, ComponentID: $ComponentID"

    $binding = Get-NetAdapter -InterfaceAlias $InterfaceAlias | Get-NetAdapterBinding -ComponentID $ComponentID

    return @{
        InterfaceAlias = $InterfaceAlias
        ComponentID = $ComponentID
        Enabled = $binding.Enabled
    }
}


function Set-TargetResource
{
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
        [string]$InterfaceAlias,

        [Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
        [string]$ComponentID,

        [Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
        [bool]$Enabled
	)

    Write-Verbose "Set-TargetResource - ComponentID: $ComponentID, Enabled: $Enabled"

    Get-NetAdapter -InterfaceAlias $InterfaceAlias | Get-NetAdapterBinding -ComponentID $ComponentID | Set-NetAdapterBinding -Enabled $Enabled
}


function Test-TargetResource
{
    param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
        [string]$InterfaceAlias,

        [Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
        [string]$ComponentID,

        [Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
        [bool]$Enabled
	)

    Write-Verbose "Test-TargetResource - ComponentID: $ComponentID, Enabled: $Enabled"

    $binding = Get-NetAdapter -InterfaceAlias $InterfaceAlias | Get-NetAdapterBinding -ComponentID $ComponentID

    if($binding -eq $null) { 
        throw "ComponentID $ComponentID not supported. Use (Get-NetAdapter -InterfaceAlias '$InterfaceAlias' | Get-NetAdapterBinding | Format-Table DisplayName, ComponentID, Enabled) to get a list of supported components." 
    }

    $testResult = [bool]($binding.Enabled -eq $Enabled)

    Write-Verbose "Test-TargetResource - Value match: $testResult"

    return $testResult
}


Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource