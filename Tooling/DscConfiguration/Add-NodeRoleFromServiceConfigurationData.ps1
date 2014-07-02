function Add-NodeRoleFromServiceConfigurationData {
    [cmdletbinding()]
    param()

    Write-Verbose 'Adding Roles to service node.'
    $UpdatedNodes = $script:ConfigurationData.AllNodes
    foreach ($Service in $script:ConfigurationData.Services.Keys) {

        $UpdatedNodes = $UpdatedNodes | 
          Add-ServiceConfigurationData -ServiceName $Service  

    }
    $script:ConfigurationData.AllNodes = $UpdatedNodes    
}

function Add-ServiceConfigurationData {
  [cmdletbinding()]
  param (
    [string]
    $ServiceName,
    [parameter(ValueFromPipeline)]
    [System.Collections.Hashtable]
    $InputObject
  )  
  process {
    Write-Verbose "`tProcessing $($InputObject.Name) for Service $ServiceName"

    if ($script:ConfigurationData.Services[$ServiceName].Nodes -contains $InputObject.Name) {
      $InputObject = $InputObject | Assert-RolesConfigurationData -ServiceName $ServiceName       
    }

    Write-Verbose "`t`tRoles on $($InputObject.Name) are: $($InputObject.Roles.Keys)"
    $InputObject
  }
}



function Assert-RolesConfigurationData {
  [cmdletbinding()]
  param (   
    [string]
    $ServiceName,
    [parameter(ValueFromPipeline)]
    [System.Collections.Hashtable]
    $InputObject
  ) 

  process {
    if (-not ($InputObject.ContainsKey('Roles'))) {
      $InputObject.Roles = @{}`
    }
    foreach ($Role in $script:ConfigurationData.Services[$ServiceName].Roles)
    {
      if ($InputObject.Roles.ContainsKey($Role)) {
        $InputObject.Roles[$Role] += $ServiceName
      }
      else {
        $InputObject.Roles.Add($Role, [string[]]$ServiceName)
      }
    }
    $InputObject
  }
}



