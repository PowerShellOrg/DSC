function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$ContainerName
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."


	<#
	$returnValue = @{
		ContainerName = [System.String]
		Accounts = [System.String[]]
		Ensure = [System.String]
	}

	$returnValue
	#>
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$ContainerName,

		[System.String[]]
		$Accounts,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

	$regIIS = $env:windir + "\MICROSOFT.NET\Framework\v4.0.30319\aspnet_regiis.exe"
	Write-Verbose "Path to command is $regIIS"

	foreach ($account in $Accounts)
	{
		if ($Ensure -eq "Present")
		{
			Write-Verbose "Authorizing $account to key store $ContainerName"
			& $regIIS -pa $ContainerName $account
		}
		elseif ($Ensure -eq "Absent")
		{
			Write-Verbose "Removing access for $account to key store $ContainerName"
			& $regIIS -pr $ContainerName $account
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
		[System.String]
		$ContainerName,

		[System.String[]]
		$Accounts,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

	$false
}


Export-ModuleMember -Function *-TargetResource

