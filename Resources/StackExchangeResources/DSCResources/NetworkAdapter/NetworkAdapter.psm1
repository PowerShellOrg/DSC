# Fallback message strings in en-US
DATA localizedData
{
    # same as culture = "en-US"
    ConvertFrom-StringData @"
"@
}

if (Test-Path $PSScriptRoot\en-us)
{
    Import-LocalizedData LocalizedData -filename "$(Split-Path $PSScriptRoot -Leaf)Provider.psd1"
}

function Get-TargetResource
{
    [OutputType([Hashtable])]
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Description,
        [parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $TeamName,
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )
    
    #Needs to return a hashtable that returns the current
    #status of the configuration component
    $Adapter = Get-NetAdapter -InterfaceDescription $Description
    if (($Adapter.Name -like $Name) -and ($Adapter.InterfaceDescription -like $Description))
    {
        $Ensure = 'Present'
    }
    else
    {
        $Ensure = 'Absent'
    }

    $Configuration = @{
        Name = $Name
        Ensure = $Ensure
        Description = $Description
    }

    return $Configuration
}

function Set-TargetResource
{
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Description,
        [parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $TeamName,
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )
    if ($Ensure -like 'Present')
    {
        Write-Verbose "Renaming $Description to $Name and enabling the adapter."
        $Preexisting = Get-NetAdapter -Name $Name
        if ($Preexisting)
        {
            $TempName = "Temp-$(Get-Random -min 1 -max 100)"
            $Preexisting | Rename-NetAdapter -NewName $TempName -Confirm:$false
            start-sleep -Seconds 1
        }
        Get-Netadapter -InterfaceDescription $Description | 
            Rename-NetAdapter -NewName $Name -confirm:$false -PassThru | 
            Enable-NetAdapter -Confirm:$false

        do
        {
            Start-Sleep -Seconds 1
        } while (-not (Get-NetAdapter -name $Name))

        if (-not [string]::IsNullOrEmpty($TeamName))
        {
            Write-Verbose "Checking for NIC Team - $TeamName"
            $Team = Get-NetLBFOTeam -Name $TeamName -ErrorAction SilentlyContinue
            $TeamMembers = ($Team | Get-NetLbfoTeamMember) | Select-Object -ExpandProperty Name
            if ($Team)
            {               
                Write-Verbose "Found NIC Team - $TeamName"
                if ($TeamMembers -notcontains $Name)
                {                
                    Write-Verbose "Adding $Name to $TeamName"
                    Add-NetLbfoTeamMember -Team "$($Team.name)" -Name $Name -Confirm:$False   
                }
                else
                {
                    Write-Verbose "$Name already exists on $TeamName"
                }
            }
            else
            {
                Write-Verbose "Team $TeamName does not exist. Creating team with $Name."
                $TeamParameters = @{
                    LoadBalancingAlgorithm = 'TransportPorts' 
                    Name = $TeamName 
                    TeamNicName = $TeamName 
                    TeamingMode = 'SwitchIndependent'
                    TeamMembers = $Name
                }
                New-NetLbfoTeam @TeamParameters
            }
        }
    }
    else
    {
        Write-Verbose "Renaming $Description to $Name and disabling the adapter."
        Get-Netadapter -InterfaceDescription $Description | 
            Rename-NetAdapter -NewName $Name -confirm:$false -PassThru | 
            Disable-NetAdapter  -confirm:$false
        
        Write-Verbose "Checking for NIC Team - $TeamName"
        $Team = Get-NetLBFOTeam -Name $TeamName -ErrorAction SilentlyContinue
        $TeamMembers = ($Team | Get-NetLbfoTeamMember) | Select-Object -ExpandProperty Name
        if ($Team)
        {
            Write-Verbose "Found NIC Teams"
            if ($TeamMembers -contains $Name)
            {  
                Write-Verbose "Found $Name in a NIC Team."
                $MemberToRemove = $Team | Get-NetLbfoTeamMember -Name $Name 
                Write-Verbose "Removing $Name from $($MemberToRemove.Team)"
                Remove-NetLbfoTeamMember -Name $MemberToRemove.Name -Team $MemberToRemove.Team
            }
        }
    }
}

function Test-TargetResource
{
    [OutputType([boolean])]
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Description,
        [parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $TeamName,
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )
    $IsValid = $true
    $Adapter = Get-NetAdapter -InterfaceDescription $Description -Verbose
    if ($Ensure -like 'Present')
    {        
        if (($Adapter -ne $null) -and ($Adapter.Name -like $Name))
        {            
            if (('Up','Disconnected') -contains $Adapter.Status)
            {
                Write-Verbose "Network Adapter $Name is named correctly and $($Adapter.Status)."
                $IsValid = $IsValid -and  $true
            }
            Write-Verbose "Network Adapter $Name is named correctly and $($Adapter.Status). It should be up or disconnected."
        }
        elseif ($Adapter -eq $null)
        {
            Write-Verbose "No adapter matching that description."
            Write-Error "No adapter matching that description."
            $IsValid = $IsValid -and  $false
        }
        else 
        {
            Write-Verbose "$($Adapter.Name) is incorrect."
            $IsValid = $IsValid -and  $false
        }

        if (-not [string]::IsNullOrEmpty($TeamName))
        {
            Write-Verbose "Checking for NIC Team - $TeamName"
            $Team = Get-NetLBFOTeam -Name $TeamName -ErrorAction SilentlyContinue

            if ($Team)
            {
                $IsValid = $IsValid -and (Test-NetAdapterTeamMembership -NICs $Name -Team $Team)
            }
            else
            {
                $IsValid = $IsValid -and  $false
            }
        }
    }
    else
    {
        if (($Adapter -ne $null) -and ($Adapter.Name -like $Name))
        {
            if (('Disabled', 'Disconnected') -contains $Adapter.Status)
            {
                Write-Verbose "Network Adapter $Name is named correctly and $($Adapter.Status)."
                $IsValid = $true
            }
            Write-Verbose "Network Adapter $Name is named correctly and $($Adapter.Status). It should be down or disconnected."
        }
        elseif ($Adapter -eq $null)
        {
            Write-Verbose "No adapter matching that description."
            Write-Error "No adapter matching that description."
        }
        else
        {
            Write-Verbose "$($Adapter.Name) is incorrect."
            $IsValid = $IsValid -and  $false
        }
    }
    
    return $IsValid
}


Function Test-NetAdapterTeamMembership 
{
	 param (
        [string[]]		
		$NICs,
		$Team
	)
    $valid = $true
    [string[]]$UsedNetAdapters = ($Team | Get-NetLbfoTeamMember).Name
    $NetAdapters = Compare-Object $UsedNetAdapters $NICs -IncludeEqual | 
        Where-Object {$NICS -contains $_.InputObject}

    switch ($NetAdapters)
    {
        {$_.SideIndicator -match "=="} {
            Write-Verbose "NIC $($_.InputObject) should be in this team and is on the team."
        }
        {$_.SideIndicator -match "<="} {
            Write-Verbose "NIC $($_.InputObject) should not be in this team."
            $Valid = $Valid -and $false
        }
        {$_.SideIndicator -match "=>"} {
            Write-Verbose "NIC $($_.InputObject) should be in this team."
            $Valid = $Valid -and $false
        }
    }
    return $valid
}