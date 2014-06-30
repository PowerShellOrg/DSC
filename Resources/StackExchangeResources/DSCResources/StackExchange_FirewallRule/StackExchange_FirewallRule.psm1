function Get-TargetResource
{
    [OutputType([Hashtable])]
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [string]
        $DisplayName,
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present',
        [parameter()]
        [ValidateSet('Allow','Block')]
        [string]
        $Action,
        [parameter()]
        [string]
        $Description,
        [parameter()]
        [ValidateSet('Inbound','Outbound')]
        [string]
        $Direction,
        [parameter()]
        [ValidateSet('Any','ProximityApps', 'ProximitySharing')]
        [string]
        $DynamicTransport,
        [parameter()]
        [ValidateSet('Block', 'Allow', 'DeferToUser','DeferToApp')]
        [string]
        $EdgeTraversalPolicy,
        [parameter()]
        [ValidateSet('True','False')]
        [string]
        $Enabled,
        [parameter()]
        [ValidateSet('NotRequired','Required','Dynamic')]
        [string]
        $Encryption,
        [parameter()]
        [string[]]
        $IcmpType,
        [parameter()]
        [string[]]
        $InterfaceAlias,
        [parameter()]
        [ValidateSet('Any','Wired','Wireless', 'RemoteAccess')]
        [string]
        $InterfaceType,
        [parameter()]        
        [string[]]
        $LocalAddress,
        [parameter()]        
        [string[]]
        $LocalPort,
        [parameter()]        
        [string]
        $LocalUser,
        [parameter()]
        [ValidateSet('Any', 'Domain','Private','Public', 'NotApplicable')]
        [string]
        $Profile,
        [parameter()]        
        [string]
        $Program,
        [parameter()]        
        [string]
        $Protocol,
        [parameter()]        
        [string[]]
        $RemoteAddress,
        [parameter()]        
        [string]
        $RemoteMachine,
        [parameter()]        
        [string]
        $RemoteUser,
        [parameter()]        
        [string]
        $Service
    )
    
    #Needs to return a hashtable that returns the current
    #status of the configuration component
    $Configuration = @{
        DisplayName = $DisplayName
    }

    $Rule = Get-NetFirewallRule -DisplayName $DisplayName -ErrorAction SilentlyContinue  | 
        ForEach-Object {
            New-Object PSObject -Property @{
                SourceRule = $_
                AddressFilter = $_ | Get-NetFirewallAddressFilter 
                ApplicationFilter = $_ | Get-NetFirewallApplicationFilter 
                InterfaceFilter = $_ | Get-NetFirewallInterfaceFilter 
                InterfaceTypeFilter = $_ | Get-NetFirewallInterfaceTypeFilter 
                PortFilter = $_ | Get-NetFirewallPortFilter 
                SecurityFilter = $_ | Get-NetFirewallSecurityFilter 
                ServiceFilter = $_ | Get-NetFirewallServiceFilter 
            }
        }
    
    if ($Rule)
    {
        $Configuration.Ensure = 'Present'

    }
    else
    {
        $Configuration.Ensure = 'Absent'
    }
    throw "To do yet"
    return $Configuration
}
 
function Set-TargetResource
{
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [string]
        $DisplayName,
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present',
        [parameter()]
        [ValidateSet('Allow','Block')]
        [string]
        $Action,
        [parameter()]
        [string]
        $Description,
        [parameter()]
        [ValidateSet('Inbound','Outbound')]
        [string]
        $Direction,
        [parameter()]
        [ValidateSet('Any','ProximityApps', 'ProximitySharing')]
        [string]
        $DynamicTransport,
        [parameter()]
        [ValidateSet('Block', 'Allow', 'DeferToUser','DeferToApp')]
        [string]
        $EdgeTraversalPolicy,
        [parameter()]
        [ValidateSet('True','False')]
        [string]
        $Enabled,
        [parameter()]
        [ValidateSet('NotRequired','Required','Dynamic')]
        [string]
        $Encryption,
        [parameter()]
        [string[]]
        $IcmpType,
        [parameter()]
        [string[]]
        $InterfaceAlias,
        [parameter()]
        [ValidateSet('Any','Wired','Wireless', 'RemoteAccess')]
        [string]
        $InterfaceType,
        [parameter()]        
        [string[]]
        $LocalAddress,
        [parameter()]        
        [string[]]
        $LocalPort,
        [parameter()]        
        [string]
        $LocalUser,
        [parameter()]
        [ValidateSet('Any', 'Domain','Private','Public', 'NotApplicable')]
        [string]
        $Profile,
        [parameter()]        
        [string]
        $Program,
        [parameter()]        
        [string]
        $Protocol,
        [parameter()]        
        [string[]]
        $RemoteAddress,
        [parameter()]        
        [string]
        $RemoteMachine,
        [parameter()]        
        [string]
        $RemoteUser,
        [parameter()]        
        [string]
        $Service
    )

    if ($PSBoundParameters.ContainsKey('Debug'))
    {
        $PSBoundParameters.Remove('Debug')
    }
    if ($PSBoundParameters.ContainsKey('Ensure'))
    {
        $PSBoundParameters.Remove('Ensure') | Out-Null
    }

    if ($Ensure -like 'Present')
    {
        Write-Verbose "Checking for an existing rule $DisplayName."
        $Rule = Get-NetFirewallRule -DisplayName $DisplayName -ErrorAction SilentlyContinue 
        if ($rule)
        {
            Set-NetFirewallRule @PSBoundParameters 
        }
        else
        {            
            New-NetFirewallRule @PSBoundParameters            
        }
    }
    else
    {        
        Remove-NetFirewallRule -DisplayName $DisplayName -Confirm:$false
    }

}

function Test-TargetResource
{
    [OutputType([Boolean])]
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [string]
        $DisplayName,
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present',
        [parameter()]
        [ValidateSet('Allow','Block')]
        [string]
        $Action = 'Allow',
        [parameter()]
        [string]
        $Description = '',
        [parameter()]
        [ValidateSet('Inbound','Outbound')]
        [string]
        $Direction = 'Inbound',
        [parameter()]
        [ValidateSet('Any','ProximityApps', 'ProximitySharing')]
        [string]
        $DynamicTransport,
        [parameter()]
        [ValidateSet('Block', 'Allow', 'DeferToUser','DeferToApp')]
        [string]
        $EdgeTraversalPolicy = 'Block',
        [parameter()]
        [ValidateSet('True','False')]
        [string]
        $Enabled = 'True',
        [parameter()]
        [ValidateSet('NotRequired','Required','Dynamic')]
        [string]
        $Encryption = 'NotRequired',
        [parameter()]
        [string[]]
        $IcmpType = 'Any',
        [parameter()]
        [string[]]
        $InterfaceAlias,
        [parameter()]
        [ValidateSet('Any','Wired','Wireless', 'RemoteAccess')]
        [string]
        $InterfaceType,
        [parameter()]        
        [string[]]
        $LocalAddress,
        [parameter()]        
        [string[]]
        $LocalPort,
        [parameter()]        
        [string]
        $LocalUser,
        [parameter()]
        [ValidateSet('Any', 'Domain','Private','Public', 'NotApplicable')]
        [string]
        $Profile,
        [parameter()]        
        [string]
        $Program,
        [parameter()]        
        [string]
        $Protocol,
        [parameter()]        
        [string[]]
        $RemoteAddress,
        [parameter()]        
        [string]
        $RemoteMachine,
        [parameter()]        
        [string]
        $RemoteUser,
        [parameter()]        
        [string]
        $Service
    )
    $Rule = Get-NetFirewallRule -DisplayName $DisplayName -ErrorAction SilentlyContinue  | 
        ForEach-Object {
            New-Object PSObject -Property @{
                SourceRule = $_
                AddressFilter = $_ | Get-NetFirewallAddressFilter 
                ApplicationFilter = $_ | Get-NetFirewallApplicationFilter 
                InterfaceFilter = $_ | Get-NetFirewallInterfaceFilter 
                InterfaceTypeFilter = $_ | Get-NetFirewallInterfaceTypeFilter 
                PortFilter = $_ | Get-NetFirewallPortFilter 
                SecurityFilter = $_ | Get-NetFirewallSecurityFilter 
                ServiceFilter = $_ | Get-NetFirewallServiceFilter 
            }
        }

    $ConfigMatches = $true
    if ($Ensure -like 'Present')
    {
        if ($Rule)
        {      
            $ConfigMatches = $ConfigMatches -and ($Rule.SourceRule.Action -like $Action)
            $ConfigMatches = $ConfigMatches -and ($Rule.SourceRule.Description -like $Description)
            $ConfigMatches = $ConfigMatches -and ($Rule.SourceRule.Direction -like $Direction)
            $ConfigMatches = $ConfigMatches -and ($Rule.SourceRule.EdgeTraversalPolicy -like $EdgeTraversalPolicy)
            $ConfigMatches = $ConfigMatches -and ($Rule.SourceRule.Enabled -like $Enabled)

            if ($DynamicTransport)
            {
                $ConfigMatches = $ConfigMatches -and ($Rule.SourceRule.DynamicTransport -like $DynamicTransport)
            }
            if ($LocalPort)
            {            
                $ConfigMatches = $ConfigMatches -and ($Rule.PortFilter.LocalPort -like $LocalPort)
                $ConfigMatches = $ConfigMatches -and ($Rule.PortFilter.Protocol -like $Protocol)
            }
            if ($LocalAddress)
            {
                $ConfigMatches = $ConfigMatches -and ($Rule.AddressFilter.LocalAddress -like $LocalAddress)
            }
            if ($RemoteAddress)
            {
                $ConfigMatches = $ConfigMatches -and ($Rule.AddressFilter.RemoteAddress -like $RemoteAddress)
            }
            if ($Program)
            {
                $ConfigMatches = $ConfigMatches -and ($Rule.ApplicationFilter.Program -like $Program)
            }

            if ($ConfigMatches)
            {
                Write-Verbose "$DisplayName is present and valid."
            }
            else
            {
                Write-Verbose "$DisplayName is not present or not valid."
            }
        }
        else
        {
            Write-Verbose "$DisplayName is not present or not valid."
            $ConfigMatches = $false
        }
    }
    else
    {
        if ($rule)
        {
            Write-Verbose "$DisplayName is present and not valid."
            $ConfigMatches = $false
        }
        Write-Verbose "$DisplayName is not present and valid."
    }
    
    return $ConfigMatches
}


