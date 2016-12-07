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
	$returnValue = @{
		ContainerName = $ContainerName
		FilePath = ""
		Ensure = ""
	}

	$returnValue
}


function Set-TargetResource
{
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$ContainerName,

		[System.String]
		$FilePath,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

	$regIIS = $env:windir + "\MICROSOFT.NET\Framework\v4.0.30319\aspnet_regiis.exe"
	Write-Verbose "Path to command is $regIIS"

	if ($Ensure -eq "Present")
	{
		Write-Verbose "Starting RSA Key Container import for $ContainerName from $FilePath"
		& $regIIS -pi $ContainerName $FilePath
	}
	elseif ($Ensure -eq "Absent")
	{
		Write-Verbose "Removing $ContainerName"
		& $regIIS -pz $ContainerName 
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

		[System.String]
		$FilePath,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)
	$false
}


Export-ModuleMember -Function *-TargetResource

