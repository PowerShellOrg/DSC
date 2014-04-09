function Resolve-ConfigurationProperty {
	[cmdletbinding()]
	param (
		[System.Collections.Hashtable]
		$Node,
		[string[]]
		$ServiceName,
		[string]
		$PropertyName,
		[switch]
		$AllowMultipleResults
	)
	
	$Value = $null 
	$Value = Assert-NodeOverride @psboundparameters
	if ($Value -eq $null) {
		$Value = Assert-SiteOverride @psboundparameters
	}
	if ($Value -eq $null) {
		$Value = Assert-GlobalSetting @psboundparameters
	}
	$Value = $Value | where-object {-not [string]::IsNullOrEmpty($_)}

	if (($Value -eq $null) -and ($ServiceName.Count -gt 0))
	{
		$psboundparameters.Remove('ServiceName') | out-null
		$Value = Resolve-ConfigurationProperty @psboundparameters
	}
	
	if ($Value -eq $null)
	{
		throw "Failed to resolve $PropertyName for $($Node.Name).  Please update your node, service, site, or all sites with a default value."
	}

	if ($AllowMultipleResults) {
		return $Value
	} 
	elseif ((-not $AllowMultipleResults) -and ($Value.count -gt 1)) {
		throw "More than one result was returned for $PropertyName for $($Node.Name).  Verify that your property configurations are correct.  If multiples are to be allowed, use -AllowMultipleResults."
	}
	else {
		return [string]$Value
	}	
}

function Assert-NodeOverride {
	[cmdletbinding()]
	param (
		[System.Collections.Hashtable]
		$Node,
		[string[]]
		$ServiceName,
		[string]
		$PropertyName,
		[switch]
		$AllowMultipleResults
	)
	$Value = $null

	if (Test-NodeOverride @psboundparameters) {
		Write-Verbose "Found a Node Override for $PropertyName."
		if ($ServiceName.count -eq 0) {
	 		$Value = $Node[$PropertyName]
		}
		else {
			$value = @()
			foreach ($Service in $ServiceName) {			
			    $Value += $Node.Services[$Service][$PropertyName]
			}
		}
		return $Value
	}
}

function Assert-SiteOverride {
	[cmdletbinding()]
	param (
		[System.Collections.Hashtable]
		$Node,
		[string[]]
		$ServiceName,
		[string]
		$PropertyName,
		[switch]
		$AllowMultipleResults
	)
	$Value = $null

	if (Test-SiteOverride @psboundparameters){
		if ($ServiceName.count -eq 0) {
	 		$Value = $ConfigurationData.SiteData[$Node.Location][$PropertyName]
		}
		else {
			$value = @()
			foreach ($Service in $ServiceName) {			
			    $Value += $ConfigurationData.SiteData[$Node.Location].Services[$Service][$PropertyName]
			}
		}
		return $Value		 
	}
}

function Assert-GlobalSetting {
	[cmdletbinding()]
	param (
		[System.Collections.Hashtable]
		$Node,
		[string[]]
		$ServiceName,
		[string]
		$PropertyName,
		[switch]
		$AllowMultipleResults
	)
	$Value = $null
	if ($ServiceName.count -eq 0) {
		if (Test-GlobalSetting @psboundparameters) {
	    	$Value = $ConfigurationData.SiteData.All[$PropertyName]
    	}
	    return $Value
	}
	else {
		$value = @()
		foreach ($Service in $ServiceName)
		{
			$psboundparameters.ServiceName = $Service
			if (Test-GlobalSetting @psboundparameters){			
			    $Value += $ConfigurationData.Services[$Service][$PropertyName]
			}
		}
		return $Value
	}
}

function Test-NodeOverride {
	[cmdletbinding()]
	param (
		[System.Collections.Hashtable]
		$Node,
		[string[]]
		$ServiceName,
		[string]
		$PropertyName,
		[switch]
		$AllowMultipleResults
	)
	$IsPresent = $false
	if (($ServiceName.count -eq 0)) {
		Write-Verbose "First Check if the Node has a key of $PropertyName"
		$IsPresent = $Node.ContainsKey($PropertyName) 
	}
	else {
		foreach ($Service in $ServiceName) {
			Write-Verbose "First Check if the Node has a key of $PropertyName for service $Service"
			$IsPresent = $Node.ContainsKey('Services') -and
				$Node.Services.ContainsKey($Service) -and 
				$Node.Services[$Service].ContainsKey($PropertyName)
			if ($IsPresent) {
				return $IsPresent
			}
		}
	}
	return $IsPresent
}

function Test-SiteOverride {
	[cmdletbinding()]
	param (
		[System.Collections.Hashtable]
		$Node,
		[string[]]
		$ServiceName,
		[string]
		$PropertyName,
		[switch]
		$AllowMultipleResults
	)
	$IsPresent = $false
	if ([string]::IsNullOrEmpty($ServiceName)) {
		Write-Verbose "Next Check if the Site has a key of $PropertyName"
		$IsPresent = (test-path variable:ConfigurationData) -and 
			$ConfigurationData.ContainsKey('SiteData') -and
			$ConfigurationData.SiteData.ContainsKey($Node.Location) -and 
			$ConfigurationData.SiteData[$Node.Location].ContainsKey($PropertyName)
	}
	else {
		Write-Verbose "Next Check if the Site has a key of $PropertyName for service $ServiceName"
		foreach ($Service in $ServiceName) {
			$IsPresent = (test-path variable:ConfigurationData) -and 
				$ConfigurationData.ContainsKey('SiteData') -and
				$ConfigurationData.SiteData.ContainsKey($Node.Location) -and 
				$ConfigurationData.SiteData[$Node.Location].ContainsKey('Services') -and
				$ConfigurationData.SiteData[$Node.Location].Services.ContainsKey($Service) -and
				$ConfigurationData.SiteData[$Node.Location].Services[$Service].ContainsKey($PropertyName)
			if ($IsPresent) {
				return $IsPresent
			}
		}
	}
	return $IsPresent
}

function Test-GlobalSetting {
	[cmdletbinding()]
	param (
		[System.Collections.Hashtable]
		$Node,
		[string[]]
		$ServiceName,
		[string]
		$PropertyName,
		[switch]
		$AllowMultipleResults
	)
	$IsPresent = $false
	if ([string]::IsNullOrEmpty($ServiceName)) {
		Write-Verbose "Finally Check if the 'All' Site has a key of $PropertyName"
		$IsPresent = (test-path variable:ConfigurationData) -and 
			$ConfigurationData.ContainsKey('SiteData') -and
			$ConfigurationData.SiteData.ContainsKey('All') -and 
			$ConfigurationData.SiteData.All.ContainsKey($PropertyName)
	}
	else {
		Write-Verbose "Finally Check if the Service has a Default Value" 
		foreach ($Service in $ServiceName) {
			$IsPresent = (test-path variable:ConfigurationData) -and 
				$ConfigurationData.ContainsKey('Services') -and
				$ConfigurationData.Services.ContainsKey($Service) -and
				$ConfigurationData.Services[$Service].ContainsKey($PropertyName)
			if ($IsPresent) {
				return $IsPresent
			}
		}
	}
	return $IsPresent
}