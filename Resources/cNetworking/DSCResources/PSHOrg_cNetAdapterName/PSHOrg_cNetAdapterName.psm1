<#
.SYNOPSIS
    DSC resource to rename network adapter

.DESCRIPTION
    DSC resource to rename network adapter using the MAC address

.NOTES
    Created: 2014-01-02
    Authors:
        Daniel Krebs
#>

function Get-TargetResource
{
    <#
    .SYNOPSIS
        Get name of network adapter
    #>
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$NewName,

		[parameter(Mandatory = $true)]
		[System.String]
		$MacAddress
	)
    # Get CIM instance
    $NetworkAdapter = Get-Win32NetworkAdapterByMacAddress -MacAddress $MacAddress

    # Prepare hashtable with CIM instance properties
	$Output = @{
		NewName = $NetworkAdapter.NetConnectionID
		MacAddress = @($NetworkAdapter.MacAddress)[0]
	}

    # Return hashtable
    Write-Output -InputObject $Output
}


function Set-TargetResource
{
    <#
    .SYNOPSIS
        Set name of network adapter
    #>
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$NewName,

		[parameter(Mandatory = $true)]
		[System.String]
		$MacAddress
	)

    # Get CIM instance and set property
    $NetworkAdapter = Get-Win32NetworkAdapterByMacAddress -MacAddress $MacAddress
    Set-CimInstance -InputObject $NetworkAdapter -Property @{NetConnectionID=$NewName}
}

function Test-TargetResource
{
    <#
    .SYNOPSIS
        Test of name the network adapter
    #>
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$NewName,

		[parameter(Mandatory = $true)]
		[System.String]
		$MacAddress
	)

    $Result = Get-TargetResource @PSBoundParameters
    
    Write-Output -InputObject ($Result.NewName -eq $NewName)    
}

function Get-Win32NetworkAdapterByMacAddress
{
    <#
    .SYNOPSIS
        Helper function to get CIM instance of network adapter
    
    .DESCRIPTION
        Helper function to get CIM instance of physical network adapter using the MAC address
    #>
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $MacAddress
    )

    begin
    {
        # Convert MAC address to match format of Win32_NetworkAdapter class
        $MacAddressConverted = cNetworking\Convert-MacAddress -MacAddress $MacAddress -Format Colon
        Write-Verbose -Message "MacAddress: $MacAddress"
        Write-Verbose -Message "MacAddress (converted): $MacAddressConverted"

        # Create CIM/WMI filter string
        $Filter = "MacAddress='$MacAddressConverted' AND PhysicalAdapter=True"
    }

    process
    {
        $NetworkAdapterArray = @(Get-CimInstance -ClassName Win32_NetworkAdapter -Filter $Filter)
        if ($NetworkAdapterArray)
        {
            if ($NetworkAdapterArray.Count -gt 1)
            {
                throw "Multiple network adapters found with the same MAC address '$MacAddressConverted'. Check your system."
            }
            
            Write-Output -InputObject $NetworkAdapterArray[0]
        }
        else
        {
            throw "Network adapter with MAC address '$MacAddressConverted' not found."
        }
    }
}

Export-ModuleMember -Function *-TargetResource