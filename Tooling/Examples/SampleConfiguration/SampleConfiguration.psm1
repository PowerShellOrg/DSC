function Test-NodeHasRole
{
    param (
        [hashtable] $Node,
        [string] $Role
    )

    return $null -ne $Node -and $Node.Roles -is [hashtable] -and $Node.Roles.ContainsKey($Role)
}

configuration SampleConfiguration
{
    node $AllNodes.NodeName
    {
        if (Test-NodeHasRole -Node $Node -Role 'RoleName')
        {
            $params = @{ ServiceName = $Node.Roles['RoleName'] }
        }
        else
        {
            $params = @{}
        }

<#
    SampleRoleResource doesn't exist; this is just a demonstration of how you make use of the
    Resolve-DscConfigurationProperty cmdlet in conjunction with the Roles / Services feature
    of the configuration data produced by the DscConfiguration tooling module.  In practice,
    SampleRoleResource might be a composite resource for this role.
#>

        SampleRoleResource RoleName
        {
            Property1 = (Resolve-DscConfigurationProperty -Node $Node @params -PropertyName 'Property1')
            Property2 = (Resolve-DscConfigurationProperty -Node $Node @params -PropertyName 'Property2')
            Property3 = (Resolve-DscConfigurationProperty -Node $Node @params -PropertyName 'Property3')
            Property4 = (Resolve-DscConfigurationProperty -Node $Node @params -PropertyName 'Property4')
        }

<#
    Here's the deal with Resolve-DscConfigurationProperty, Nodes, Sites, Services and Roles, as it
    can be a little confusing to see how these all fit together.

    A node must be a member of exactly one site.  Leaving services and roles out of the picture for
    the moment, a property can be defined directly on a Node, in the Node's site, or in a site named
    'All' which stores global properties.  (Properties defined in a Node with NodeName of '*' wind up
    applied directly to the $Node variable, so override Site settings.)

    If you pass a value to the -ServiceName parameter when calling Resolve-DscConfigurationProperty,
    settings defined in those service files take precedence over everything else.  If no matching
    property is found in any of the specified ServiceNames, it falls back to checking the Node,
    Site and Global settings.

    Nodes may be members of any number of services, and each service can be associated with any number
    of Roles.  Roles can be thought of as a group of related settings, whereas Services are groups of
    related Nodes.  You might pull properties from several different places to get all of the settings
    required for a particular Role.

    For example, you might have a role called 'VMSettings' which is responsible for configuring the
    disk space, memory size and other performance-related settings of Hyper-V VMs.  Different classes
    of VMs may have different needs here; a domain controller or file / print server can get by with
    relatively low resources, but a production SQL or Web server would need a lot more RAM, might want
    to store its VHD files on a faster disk, and so on.

    All of these various Services (WebServer, DBServer, DomainController, FileServer) would contain
    'VMSettings' in their Roles list.  When you run Get-ConfigurationData, nodes that are members of
    services will have a $Node.Roles hashtable which maps Role names to arrays of one or more Service
    names.  This array of service names is what's meant to be passed to Resolve-DscConfigurationProperty,
    as seen in the above example code.

    Note:  Because a node may be part of multiple Services which contain the same Role, and potentially
    define the same settings within that Role, it's possible for conflicts to occur.  By default,
    Resolve-DscConfigurationProperty will throw an error if such a conflict for a particular Property is
    detected, causing your whole configuration to fail.  If you are resolving a property that's supposed
    to have multiple values (or you want to handle the conflict in another way), use the -AllowMultipleResults
    switch when calling Resolve-DscConfigurationProperty.  It will then return an array containing all of the
    matching values for that Property from any service.

    Going back to our VMSettings role example, maybe a particular VM is acting as both a web server and a
    file / print server.  If you wanted to set the memory to the largest value from whatever services
    defined that option, you could do something like this:

    $MemorySize = Resolve-DscConfigurationProperty -Node $Node -ServiceName $Node.Roles['VMSettings'] -PropertyName MemorySize -AllowMultipleResults |
                  Sort-Object -Descending |
                  Select-Object -First 1
#>
    }
}
