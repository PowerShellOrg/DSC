function Resolve-DscConfigurationProperty
{
    <#
        .Synopsis
            Searches DSC metadata
    #>

    [cmdletbinding()]
    param (
        #The current node being evaluated for the specified property.
        [System.Collections.Hashtable]
        $Node,

        #By default, all services associated with a Node are checked for the specified Property.  If you want to filter this down to specific service(s), pass one or more strings to this parameter.  Wildcards are allowed.
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ServiceName = '*',

        #The property that will be checked for.
        [parameter(Mandatory)]
        [string]
        $PropertyName,

        #By default, all results must return just one entry.  If you want to fetch values from multiple services or from all scopes, set this parameter to 'MultipleValuesFromServiceOnly' or 'AllValues', respectively.
        [ValidateSet('SingleValueOnly', 'MultipleValuesFromServiceOnly', 'AllValues')]
        [string] $MultipleResultBehavior = 'SingleValueOnly',

        #If you want to override the default behavior of checking up-scope for configuration data, it can be supplied here.
        [System.Collections.Hashtable]
        $ConfigurationData
    )

    Write-Verbose ""
    if ($null -eq $ConfigurationData)
    {
        Write-Verbose ""
        Write-Verbose "Resolving ConfigurationData"

        $ConfigurationData = $PSCmdlet.GetVariableValue('ConfigurationData')

        if ($ConfigurationData -isnot [hashtable])
        {
            throw 'Failed to resolve ConfigurationData.  Please confirm that $ConfigurationData is property set in a scope above this Resolve-DscConfigurationProperty or passed to Resolve-DscConfigurationProperty via the ConfigurationData parameter.'
        }
    }

    $doGetAllResults = $MultipleResultBehavior -eq 'AllValues'

    Write-Verbose "Starting to evaluate $($Node.Name) for PropertyName: $PropertyName and resolution behavior: $MultipleResultBehavior"

    $Value = @(Get-NodeValue -Node $Node -ConfigurationData $ConfigurationData -PropertyName $PropertyName)
    Write-Verbose "Value after checking the node is $Value"

    if ($doGetAllResults -or $Value.count -eq 0)
    {
        $Value += @(Get-ServiceValue -Node $Node -ConfigurationData $ConfigurationData -PropertyName $PropertyName -ServiceName $ServiceName)
        Write-Verbose "Value after checking services is $Value"
    }

    if ($doGetAllResults -or $Value.count -eq 0)
    {
        $Value += @(Get-SiteValue -Node $Node -ConfigurationData $ConfigurationData -PropertyName $PropertyName)
        Write-Verbose "Value after checking the site is $Value"
    }

    if ($doGetAllResults -or $Value.count -eq 0)
    {
        $Value += @(Get-GlobalValue -ConfigurationData $ConfigurationData -PropertyName $PropertyName)
        Write-Verbose "Value after checking the global is $Value"
    }

    if ($Value.count -eq 0)
    {
        throw "Failed to resolve $PropertyName for $($Node.Name).  Please update your node, service, site, or all sites with a default value."
    }

    if (($MultipleResultBehavior -eq 'SingleValueOnly') -and ($Value.count -gt 1))
    {
        throw "More than one result was returned for $PropertyName for $($Node.Name).  Verify that your property configurations are correct.  If multiples are to be allowed, set -MultipleResultBehavior to MultipleValuesFromServiceOnly or AllValues."
    }
    else
    {
        return $Value
    }
}

Set-Alias -Name 'Resolve-ConfigurationProperty' -Value 'Resolve-DscConfigurationProperty'

function Get-NodeValue
{
    [cmdletbinding()]
    param (
        [System.Collections.Hashtable]
        $Node,
        [string]
        $PropertyName,
        [System.Collections.Hashtable]
        $ConfigurationData
    )

    if ($null -eq $Node) { return }

    $resolved = $null

    Write-Verbose "    Checking Node: $($Node.Name)"

    if (Resolve-HashtableProperty -Hashtable $Node -PropertyName $PropertyName -Value ([ref] $resolved))
    {
        Write-Verbose "        Found Node Value: $resolved"
        $resolved
    }

    Write-Verbose "    Finished checking Node $($Node.Name)"
}

function Get-ServiceValue
{
    [CmdletBinding()]
    param (
        [hashtable] $Node,
        [string] $PropertyName,
        [hashtable] $ConfigurationData,
        [string[]] $ServiceName
    )

    if ($null -eq $Node) { return }

    $servicesTable = $ConfigurationData['Services']
    if ($servicesTable -isnot [hashtable]) { return }

    $resolved = $null
    foreach ($keyValuePair in $servicesTable.GetEnumerator())
    {
        $name = $keyValuePair.Key
        $serviceValue = $keyValuePair.Value

        if ($serviceValue -is [hashtable] -and (ShouldProcessService -Name $name -Service $serviceValue -Filter $ServiceName -NodeName $node.Name))
        {
            Write-Verbose "    Checking Service $name"

            if (Resolve-HashtableProperty -Hashtable $serviceValue -PropertyName $PropertyName -Value ([ref] $resolved))
            {
                Write-Verbose "        Found Service Value: $resolved"
                $resolved
            }

            Write-Verbose "    Finished checking Service $name"
        }
    }
}

function ShouldProcessService
{
    param (
        [string] $Name,
        [hashtable] $Service,
        [string[]] $Filter = @(),
        [string] $NodeName
    )

    if (-not [string]::IsNullOrEmpty($NodeName) -and -not $Service['Nodes'] -contains $NodeName)
    {
        return $false
    }

    $foundMatchingFilter = $false
    foreach ($pattern in $Filter)
    {
        if ($Name -like $pattern)
        {
            $foundMatchingFilter = $true
            break
        }
    }

    return $foundMatchingFilter
}

function Get-SiteValue
{
    [cmdletbinding()]
    param (
        [System.Collections.Hashtable]
        $Node,
        [string]
        $PropertyName,
        [System.Collections.Hashtable]
        $ConfigurationData
    )

    if ($null -eq $Node -or -not $Node.ContainsKey('Location')) { return }

    return Resolve-SiteProperty -PropertyName $PropertyName -ConfigurationData $ConfigurationData -Site $Node.Location
}

function Get-GlobalValue
{
    [cmdletbinding()]
    param (
        [string]
        $PropertyName,
        [System.Collections.Hashtable]
        $ConfigurationData
    )

    return Resolve-SiteProperty -ConfigurationData $ConfigurationData -PropertyName $PropertyName -Site All
}

function Resolve-SiteProperty
{
    [cmdletbinding()]
    param (
        [string]
        $PropertyName,
        [System.Collections.Hashtable]
        $ConfigurationData,
        [string]
        $Site
    )

    $resolved = $null

    Write-Verbose "    Checking Site $Site"
    if (Resolve-HashtableProperty -Hashtable $ConfigurationData -PropertyName "SiteData\$Site\$PropertyName" -Value ([ref] $resolved))
    {
        Write-Verbose "        Found Site Value: $resolved"
        $resolved
    }

    Write-Verbose "    Finished checking Site $Site"
}

function Resolve-HashtableProperty
{
    [OutputType([bool])]
    param (
        [hashtable] $Hashtable,
        [string] $PropertyName,
        [ref] $Value
    )

    $properties = $PropertyName -split '\\'
    $currentNode = $Hashtable

    foreach ($property in $properties)
    {
        if ($currentNode -isnot [hashtable] -or $null -eq $currentNode[$property]) { return $false }
        $currentNode = $currentNode[$property]
    }

    $Value.Value = $currentNode
    return $true
}
