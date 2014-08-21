<### 
 # SHT_NetAdapterAdvancedProperty - A DSC resource for modifying network adapter driver settings
 # Authored by: M.T.Nielsen - mni@systemhosting.dk
 #>
function Get-TargetResource
{
    [CmdletBinding()]
	param
	(		
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
        [string]$InterfaceAlias,

        [Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
        [string]$RegistryKeyword
	)
	
    Write-Verbose "Get-TargetResource - InterfaceAlias: $InterfaceAlias, Keyword: $RegistryKeyword"
    
    $registryValue = Get-NetAdapter -InterfaceAlias $InterfaceAlias | Get-NetAdapterAdvancedProperty -RegistryKeyword $RegistryKeyword | Select-Object -ExpandProperty RegistryValue

    return @{
        InterfaceAlias = $InterfaceAlias
        RegistryKeyword = $RegistryKeyword
        RegistryValue = $registryValue
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
		[ValidateNotNullOrEmpty()]
        [string]$RegistryKeyword,

        [Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
        [string]$RegistryValue
	)

    Write-Verbose "Set-TargetResource - RegistryKeyword: $RegistryKeyword, RegistryValue: $RegistryValue"

    Get-NetAdapter -InterfaceAlias $InterfaceAlias | Get-NetAdapterAdvancedProperty -RegistryKeyword $RegistryKeyword | Set-NetAdapterAdvancedProperty -RegistryValue $RegistryValue
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
		[ValidateNotNullOrEmpty()]
        [string]$RegistryKeyword,

        [Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
        [string]$RegistryValue
	)

    Write-Verbose "Test-TargetResource - RegistryKeyword: $RegistryKeyword, RegistryValue: $RegistryValue"

    $property = Get-NetAdapter -InterfaceAlias $InterfaceAlias | Get-NetAdapterAdvancedProperty -RegistryKeyword $RegistryKeyword

    if($property -eq $null) { 
        throw "RegistryKeyword $RegistryKeyword not supported. Use (Get-NetAdapter -InterfaceAlias '$InterfaceAlias' | Get-NetAdapterAdvancedProperty | Format-Table DisplayName, RegistryKeyword, RegistryValue, ValidRegistryValues) to get a list of supported keywords and values." 
    }

    $testResult = [bool]($property.RegistryValue -eq $RegistryValue)

    Write-Verbose "Test-TargetResource - Value match: $testResult"

    return $testResult
}

 
Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource