

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
        if (Test-NetAdapterName -Name $Name -Description $Description)
        {
            Write-Verbose "Adapter with $Description already named Correctly."
        }
        else
        {
            Write-Verbose "If the adapter name is already used, rename it to a temporary name."
            Rename-NetAdapterWithWait -Name $Name -NewName "Temp-$(Get-Random -min 1 -max 100)"
            Write-Verbose "Rename the network adapter."
            Rename-NetAdapterWithWait -Name (Get-NetAdapter -InterfaceDescription $Description).Name -NewName $Name       
        }

        if (Test-NetAdapterTeamMembership -Name $Name -TeamName $TeamName)
        {
            Write-Verbose "Network adapter is correctly configured for teaming."
        }
        else
        {            
            Remove-MismatchedNetLbfoTeamMember -TeamName $TeamName -Name $Name   
            New-NetLbfoTeamMember -TeamName $TeamName -Name $Name   
        }
    }
    else
    {   
        if (Test-NetAdapterName -Name $Name -Description $Description)
        {
            Write-Verbose "Adapter should not be named $Name."
            Write-Verbose "renaming it to a temporary name."
            Rename-NetAdapterWithWait -Name $Name -NewName "Temp-$(Get-Random -min 1 -max 100)"
        }
        else
        {
            Write-Verbose "Adapter with description $Description is not named $Name."
        }
        Write-Verbose "Clearing team membership."
        Remove-MismatchedNetLbfoTeamMember -TeamName $TeamName -Name (Get-NetAdapter -InterfaceDescription $Description).Name -RemoveFromAll
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
        $TeamName = '',
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )
    $IsValid = $true
    Write-Verbose "Checking if network adapter with $Description exists."
    $IsValid = (Test-NetAdapterExists -Description $Description) -and $IsValid
    Write-Verbose "Checking if network adapter is named correctly."
    $IsValid = (Test-NetAdapterName -Name $Name -Description $Description) -and $IsValid
    Write-Verbose "Checking if network adapter is teamed correctly."
    $IsValid = (Test-NetAdapterTeamMembership -TeamName $TeamName -Name $Name) -and $IsValid

    
    if ($Ensure -like 'Absent')
    {
        Write-Verbose "Adapter $Description should not have $Name."
        $IsValid = -not $IsValid 
    }
    
    Write-Verbose "Network adapter status is"
    return $IsValid
}

#region Support Functions
function Test-NetAdapterExists
{
    [cmdletbinding()]
    param (
        [string]$Description
    )
    if (Get-NetAdapter -InterfaceDescription $Description)
    {
        Write-Verbose "Network adapter with $Description exists."
        return $true
    }
    else
    {
        throw "No adapter matching that description."  
    }
    
}

function Test-NetAdapterName
{
    [cmdletbinding()]
    param (
        [string]$Name,
        [string]$Description
    )
    $Adapter = Get-NetAdapter -Name $Name  -ErrorAction SilentlyContinue

    if ( $Adapter | Where-Object {$_.InterfaceDescription -like $Description} )
    {
        Write-Verbose "The Name $Name is already used by the right adapter."
        return $true
    }
    elseif ( $Adapter | Where-Object {$_.InterfaceDescription -notlike $Description} )
    {
        Write-Verbose "The Name $Name is already being used by another adapter."
        return $false
    }
    else
    {
        Write-Verbose "The Name $Name is not in use "
        return $false
    }
}

function Test-NetAdapterState
{
    param (
        [string]$State, 
        [switch]$Up, 
        [switch]$Disconnected, 
        [switch]$Disabled
    )

    $ValidStates = @()
    if ($Up)
    {
        $ValidStates += 'Up'
    }
    if ($Disabled)
    {
        $ValidStates += 'Disabled'
    }
    if ($Disconnected)
    {
        $ValidStates += 'Disconnected'
    }

    $OFS = ', '
    Write-Verbose "Valid states are $ValidStates."
    Write-Verbose "Current state is $state."
    return ($ValidStates -contains $State)

}

function Test-NetAdapterTeamMembership
{
    [cmdletbinding()]
    param ([string]$Name, [string]$TeamName)

    Write-Verbose "Testing if $Name is present in NIC Team - $TeamName"
    $IsValid = $true
    $ShouldBeOnTeam = -not [string]::IsNullOrEmpty($TeamName)

    Write-Verbose "Checking for NIC to be present in $TeamName"
    $TeamMember = Get-NetLbfoTeamMember -Name $Name -ErrorAction SilentlyContinue

    if ($TeamMember -and $ShouldBeOnTeam)
    {
        Write-Verbose "NIC $Name is in a team - $($TeamMember.Team)."
        $IsValid = ($TeamMember.Team -like $TeamName) -and $IsValid
    }
    elseif ($ShouldBeOnTeam)
    {
        Write-Verbose "$Name is not in a team."
        $IsValid = $IsValid -and $false
    }
    elseif ($TeamMember -and (-not $ShouldBeOnTeam))
    {
        Write-Verbose "$Name is in a team and should not be."
        $IsValid = $IsValid -and $false
    }
    else
    {
        Write-Verbose "$Name is not in a team and should not be."
    }

    return $IsValid
}

function Remove-MismatchedNetLbfoTeamMember
{
    [cmdletbinding()]
    param (
        [string]$Name,
        [string]$TeamName,
        [switch]$RemoveFromAll
    )

    Get-NetLbfoTeamMember -Name $Name -ErrorAction SilentlyContinue | 
        Where-Object { if ($RemoveFromAll) {$true} else {$_.Team -notlike $TeamName} } | 
        ForEach-Object {
            $TeamMember = $_
            try 
            {
                Write-Verbose "Removing $Name from team $($TeamMember.team)."
                Remove-NetLbfoTeamMember -Name $TeamMember.name -Team $TeamMember.Team -Confirm:$false -ErrorAction Stop
            }
            catch
            {
                Write-Verbose "Failed to remove $Name from team $($TeamMember.team)."
                Write-Verbose "Removing team $($TeamMember.Team)."
                Remove-NetLbfoTeam -Name $TeamMember.Team -Confirm:$false
            }
        }
}

function New-NetLbfoTeamMember
{
    [cmdletbinding()]
    param (
        [string]$Name,
        [string]$TeamName
    )

    Write-Verbose "Checking for NIC Team - $TeamName"
    if (Get-NetLBFOTeam -Name $TeamName -ErrorAction SilentlyContinue)
    {
        Write-Verbose "Adding NIC $Name to team $teamname."
        Add-NetLbfoTeamMember -Team $TeamName -Name $Name -Confirm:$false
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
            Confirm = $false
        }
        New-NetLbfoTeam @TeamParameters 
    }
    

}

function Rename-NetAdapterWithWait
{
    [cmdletbinding()]
    param (
        $Name, 
        $NewName
    )

    Get-NetAdapter -Name $Name -ErrorAction SilentlyContinue | 
        Rename-NetAdapter -NewName $NewName -Confirm:$false |
        ForEach-Object {            
            while ( -not (Get-NetAdapter -Name $NewName -ErrorAction SilentlyContinue) )
            {
                Write-Verbose "Waiting for rename of improperly named NIC to take effect."
                Start-Sleep -Seconds 2
            }
            Write-Verbose "Improperly named NIC has been renamed."
        }
}
#endregion


