function Resolve-ConfigurationProperty {
	<#
		.Synopsis
			Short description of the command
		.Description
			Longer description of the command 
		.Example
			
	#>
	[cmdletbinding()]
	param (
		#The current node being evaluated for the specified property or application.
		[parameter()]
		[System.Collections.Hashtable]
		$Node,

		#The service(s) that will be checked for the specified property or application.
		[parameter()]
		[ValidateNotNullOrEmpty()]
		[string[]]
		$ServiceName,

		#The 
		[parameter()]
		[ValidateNotNullOrEmpty()]
		[string]
		$Application,

		#
		[parameter()]
		[ValidateNotNullOrEmpty()]
		[string]
		$PropertyName,

		#
		[parameter()]
		[switch]
		$AllowMultipleResults
	)
	Write-Verbose "Starting to evaluate $($Node.Name) for PropertyName: $PropertyName Application: $Application From Services: $ServiceName"

	$Value = @()
	if (($Node -ne $null)) {
		$Value = Assert-NodeOverride @psboundparameters
		Write-Verbose "Value after checking the node is $Value"
	}	
	if (-not $psboundparameters.ContainsKey('Application')) {
		$Value = ($Value | where-object {-not [string]::IsNullOrEmpty($_)})
	}

	if ($Value.count -eq 0) {
		$Value += Assert-SiteOverride @psboundparameters
		Write-Verbose "Value after checking the site is $Value"
	}
	if (-not $psboundparameters.ContainsKey('Application')) {
		$Value = ($Value | where-object {-not [string]::IsNullOrEmpty($_)})
	}

	if ($Value.count -eq 0) {
		$Value += Assert-GlobalSetting @psboundparameters
		Write-Verbose "Value after checking the global is $Value"
	}
	if (-not $psboundparameters.ContainsKey('Application')) {
		$Value = ($Value | where-object {-not [string]::IsNullOrEmpty($_)})
	}
	
	if (-not $psboundparameters.ContainsKey('Application')) {
		if (($Value.count -eq 0) -and ($ServiceName.Count -gt 0))
		{
			$psboundparameters.Remove('ServiceName') | out-null
			$Value = Resolve-ConfigurationProperty @psboundparameters
		}

		if ($Value.count -eq 0)
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
			return $Value
		}	
	}
	else {
		if ($value -eq $null) {
			$psboundparameters.Remove('ServiceName') | out-null
			$Value = Resolve-ConfigurationProperty @psboundparameters
		}
		if ($value -is [System.Collections.Hashtable]) {
			return $value
		}
		else {
			throw "Failed to resolve $Application for $($Node.Name).  Please update your node, service, site, or all sites with a default value."
		}
	}
}

function Test-HashtableKey {
	[cmdletbinding()]
	param (
		[parameter(position=0)]
		[System.Collections.Hashtable]
		$Hashtable, 
		[parameter(position=1)]
		[string]
		$key,
		$NumberOfTabs
	)
	if ($Hashtable -ne $null) {
		#Write-Verbose (("`t" * $NumberOfTabs) + "$((Get-PSCallStack)[1].Command)")
		#Write-Verbose (("`t" * $NumberOfTabs) + "$((Get-PSCallStack)[1].ScriptLineNumber)")
		$ofs = ', '
		Write-Verbose (("`t" * $NumberOfTabs) + "Testing for $key from ( $($Hashtable.keys) )")
		$Found = $Hashtable.ContainsKey($key)
		Write-Verbose (("`t" * $NumberOfTabs) + "$key was found: $Found")
		return $found
	}
	return $false
}

function Test-ApplicationKey {
	param (
		[System.Collections.Hashtable]
		$Hashtable,
		[string]
		$Application
	)
	$NumberOfTabs = 3
	if ($Hashtable -ne $null) {
		if (-not [string]::IsNullOrEmpty($Application)) {
			if (Test-HashtableKey $Hashtable 'Applications' -NumberOfTabs $NumberOfTabs) {
				$NumberOfTabs++
				if (Test-HashtableKey $Hashtable['Applications'] $Application -NumberOfTabs $NumberOfTabs) {
						Write-Verbose ("`t" * $NumberOfTabs + "Found $Application")
						return $true					
				}
			}
		}
	}
	return $false
}

function Test-ServiceKey {
	param (
		[System.Collections.Hashtable]
		$Hashtable,
		[string]
		$Service,
		[string]
		$PropertyName
	)
	$NumberOfTabs = 3
	if ($Hashtable -ne $null) {
		if (-not [string]::IsNullOrEmpty($Service)) {
			if (Test-HashtableKey $Hashtable 'Services' -NumberOfTabs $NumberOfTabs) {
				$NumberOfTabs++
				if (Test-HashtableKey $Hashtable['Services'] $Service -NumberOfTabs $NumberOfTabs) {
					$NumberOfTabs++
					if (Test-HashtableKey $Hashtable['Services'][$Service] $PropertyName -NumberOfTabs $NumberOfTabs) {
						return $true
					}
				}
			}
		}
	}
	return $false
}


function Resolve-HashtableProperty {
	param (
		[System.Collections.Hashtable]
		$Hashtable,
		[string]
		$PropertyName
	)	
	
	if ($Hashtable -ne $null) {
		$PropertyValue = $Hashtable[$PropertyName]
		if ($PropertyValue -ne $null) {
		 	Write-Verbose "`t`t`t$Found PropertyName $PropertyName with value $PropertyValue"
		 	return $PropertyValue
		}
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
		$Application,
		[string]
		$PropertyName,
		[switch]
		$AllowMultipleResults
	)
	$Value = @()	
	Write-Verbose "`tChecking Node: $($Node.Name)"		
	if (( $ServiceName.count -eq 0 ) -and 
		( -not [string]::IsNullOrEmpty($Application) ) -and 
	 	( Test-ApplicationKey -Hashtable $Node -Application $Application )) {
		
		$Value += Resolve-HashtableProperty $Node['Applications'] $Application
		
	}
	elseif (($ServiceName.count -eq 0) -and 
			( Test-HashtableKey $Node $PropertyName -NumberOfTabs 2)) {			
		$Value += Resolve-HashtableProperty $Node $PropertyName		
	}
	else {			
		foreach ($Service in $ServiceName) {	
			if ( Test-HashtableKey $Node 'Services' -NumberOfTabs 2) {
				if (Test-HashtableKey $Node['Services'] $Service -NumberOfTabs 3) {

					if ( Test-ServiceKey -Hashtable $Node -Service $Service -PropertyName $PropertyName ) {
						$Value += Resolve-HashtableProperty $Node['Services'][$Service] $PropertyName
					}
					elseif (Test-ApplicationKey -Hashtable $Node['Services'][$Service] -Application $Application)  {
						$Value += Resolve-HashtableProperty $Node['Services'][$Service]['Applications'] $Application
					}
				}
			}
		}
	}

	if ($value.count -gt 0) {
		Write-Verbose "`t`tFound Node Value: $Value"		
	}
	Write-Verbose "`tFinished checking Node $($Node.Name)"
	return $Value	
}

function Assert-SiteOverride {
	[cmdletbinding()]
	param (
		[System.Collections.Hashtable]
		$Node,
		[string[]]
		$ServiceName,
		[string]
		$Application,
		[string]
		$PropertyName,
		[switch]
		$AllowMultipleResults
	)
	$Value = @()	
	$Site = $Node.Location
	Write-Verbose "`tStarting to check Site $Site"
	if ((Test-HashtableKey $ConfigurationData 'SiteData' -NumberOfTabs 2) -and 
			 (Test-HashtableKey $ConfigurationData.SiteData $Site -NumberOfTabs 2)
	 	) {
		if ( ($ServiceName.count -eq 0) -and 
				(-not [string]::IsNullOrEmpty($Application)) -and 
				(Test-ApplicationKey -Hashtable $ConfigurationData.SiteData[$Site] -Application $Application )) {
			$Value += Resolve-HashtableProperty $ConfigurationData.SiteData[$Site]['Applications']	$Application
			
		}
		elseif ( ($ServiceName.count -eq 0) -and 
					(Test-HashtableKey $ConfigurationData.SiteData[$Site] $PropertyName ) ){			
				$Value += Resolve-HashtableProperty $ConfigurationData.SiteData[$Site] $PropertyName
		}
		else {
			foreach ($Service in $ServiceName) {
				if (Test-HashtableKey $ConfigurationData.SiteData[$Site] 'Services' -NumberOfTabs 2) {
					if (Test-HashtableKey $ConfigurationData.SiteData[$Site]['Services'] $Service -NumberOfTabs 3)  {
						if (Test-ApplicationKey -Hashtable $ConfigurationData.SiteData[$Site]['Services'][$Service] -Application $Application)  {
							$Value += Resolve-HashtableProperty $ConfigurationData.SiteData[$Site]['Services'][$Service]['Applications'] $Application
						}
						elseif ( Test-ServiceKey -Hashtable $ConfigurationData.SiteData[$Site] -Service $Service -PropertyName $PropertyName ) {
							$Value += Resolve-HashtableProperty $ConfigurationData.SiteData[$Site]['Services'][$Service] $PropertyName
						}
					}					
				}
			}
		}
	}	
	Write-Verbose "`tFinished checking Site $Site"
	return $Value		 
}

function Assert-GlobalSetting {
	[cmdletbinding()]
	param (
		[System.Collections.Hashtable]
		$Node,
		[string[]]
		$ServiceName,
		[string]
		$Application,
		[string]
		$PropertyName,
		[switch]
		$AllowMultipleResults
	)
	$Value = @()
	Write-Verbose "Bound parameters include:"
	foreach ($key in $psboundparameters.keys) {
		Write-Verbose "`t$key is $($psboundparameters[$key])"
	}
	Write-Verbose "`tStarting to check global settings"
	if ($ServiceName.count -eq 0) {
		if (-not [string]::IsNullOrEmpty($Application)) {
			if (Test-ApplicationKey -Hashtable $ConfigurationData -Application $Application) {
				$Value += Resolve-HashtableProperty $ConfigurationData['Applications'] $Application
			}
		}
		else {
			Write-Verbose "`t`tStarting to check Site: All"
			if (Test-HashtableKey $ConfigurationData 'SiteData' -NumberOfTabs 3) {
				if (Test-HashtableKey $ConfigurationData.SiteData 'All' -NumberOfTabs 4) {
					if (Test-HashtableKey $ConfigurationData.SiteData.All $PropertyName -NumberOfTabs 5) {
						$Value += Resolve-HashtableProperty $ConfigurationData.SiteData.All $PropertyName				 	
				    }
				}
			}
    	}	    
    	Write-Verbose "`t`tFinished checking Site: All"
	}
	else {
		foreach ($Service in $ServiceName) {
			Write-Verbose "`t`tStarting to check Service:$Service"
			$Found = $false
			if (Test-HashtableKey $ConfigurationData 'SiteData' -NumberOfTabs 3) {
				if (Test-HashtableKey $ConfigurationData.SiteData 'All' -NumberOfTabs 4) {
					if (Test-HashtableKey $ConfigurationData.SiteData.All 'Services' -NumberOfTabs 5) {
						if (Test-HashtableKey $ConfigurationData.SiteData.All.Services $Service -NumberOfTabs 6) {
							if (Test-ServiceKey -Hashtable $ConfigurationData.SiteData.All -Service $Service -PropertyName $PropertyName) {
								$Found = $true
								$Value += Resolve-HashtableProperty $ConfigurationData.SiteData.All.Services[$Service] $PropertyName							    
							}
							elseif (Test-ApplicationKey -Hashtable $ConfigurationData.SiteData.All.Services[$Service] -Application $Application) {
								$Found = $true
								$Value += Resolve-HashtableProperty $ConfigurationData.SiteData.All.Services[$Service]['Applications'] $Application
							}
						}
					}
				}
			}		
			if ((-not $found) -and (Test-HashtableKey $ConfigurationData 'Services' -NumberOfTabs 3)) {
				if (Test-HashtableKey $ConfigurationData.Services $Service -NumberOfTabs 4) {
					if (Test-ServiceKey -Hashtable $ConfigurationData -Service $Service -PropertyName $PropertyName) {
						$Value += Resolve-HashtableProperty $ConfigurationData.Services[$Service] $PropertyName
					}
					elseif (Test-ApplicationKey -Hashtable $ConfigurationData.Services[$Service] -Application $Application ) {
						$Value += Resolve-HashtableProperty $ConfigurationData.Services[$Service]['Applications'] $Application
					}
				}
			}
			
			Write-Verbose "`t`tFinished checking Service:$Service"
		}		
	}
	Write-Verbose "`tFound Global Value: $Value"
	return $Value
}








