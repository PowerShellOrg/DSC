# DscConfiguration module required for the Resolve-DscConfigurationProperty and Test-NodeHasRole functions.
Import-Module DscConfiguration -ErrorAction Stop

configuration SampleConfiguration
{
    Import-DscResource -ModuleName StackExchangeResources
    Import-DscResource -ModuleName cWebAdministration
    Import-DscResource -ModuleName cSmbShare

    node $AllNodes.NodeName
    {
        if (Test-NodeHasRole -Node $Node -Role 'BaseServer')
        {
            $services = @{ ServiceName = $Node.Roles['BaseServer'] }
        }
        else
        {
            $services = @{}
        }

        # This is a fairly silly example, choosing a power plan based on alphabetical order.  However, it does demonstrate how
        # you can deal with potential conflicts betwee your services when they contribute a setting to the same role, and in
        # this case, 'High Performance' is "greater than" 'Balanced'.

        $PowerPlan = Resolve-DscConfigurationProperty -Node $Node @services -PropertyName 'PowerPlan' -AllowMultipleResults |
                     Sort-Object -Descending |
                     Select-Object -First 1

        PowerPlan PowerPlan
        {
            Name = $PowerPlan
        }

        if (Test-NodeHasRole -Node $Node -Role 'FileServer')
        {
            WindowsFeature FS-FileServer
            {
                Name   = 'FS-FileServer'
                Ensure = 'Present'
            }

            $shares = @(
                Resolve-DscConfigurationProperty -Node $Node -ServiceName $Node.Roles['FileServer'] -PropertyName Shares -AllowMultipleResults
            )

            foreach ($share in $shares)
            {
                cSmbShare "SmbShare_$($share['Name'])"
                {
                    DependsOn  = '[WindowsFeature]FS-FileServer'
                    Name       = $share['Name']
                    Path       = $share['Path']
                    FullAccess = @($share['FullAccess'])
                    ReadAccess = @($share['ReadAccess'])
                }
            }
        }

        if (Test-NodeHasRole -Node $Node -Role 'WebServer')
        {
            #ApplyWebServerSettings -Node $Node

            WindowsFeature Web-Server
            {
                Name   = 'Web-Server'
                Ensure = 'Present'
            }

            $websites = @(
                Resolve-DscConfigurationProperty -Node $Node -ServiceName $Node.Roles['WebServer'] -PropertyName Websites -AllowMultipleResults
            )

            foreach ($website in $websites)
            {
                File "Website_$($website['Name'])_Files"
                {
                    DestinationPath = $website['LocalPath']
                    SourcePath = $website['SourcePath']
                    Ensure = 'Present'
                    Type = 'Directory'
                    Checksum = 'SHA-1'
                    Recurse = 'True'
                    Force = 'True'
                    MatchSource = 'True'
                }

                cWebsite "Website_$($website['Name'])"
                {
                    DependsOn = "[WindowsFeature]Web-Server", "[File]Website_$($website['Name'])_Files"
                    Name = $website['Name']
                    PhysicalPath = $website['LocalPath']
                }
            }
        }

        if ($Node.Name -eq 'FileServer01')
        {
            # This is just to demonstrate how node identical properties defined at the Node level override
            # those defined at the site level, if present.

            $property1 = Resolve-DscConfigurationProperty -Node $Node -PropertyName ExampleProperty1
            $property2 = Resolve-DscConfigurationProperty -Node $Node -PropertyName ExampleProperty2

            Write-Verbose -Verbose "ExampleProperty1: $property1"
            Write-Verbose -Verbose "ExampleProperty2: $property2"
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
