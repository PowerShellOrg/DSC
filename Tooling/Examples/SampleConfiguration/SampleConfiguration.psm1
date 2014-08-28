# DscConfiguration module required for the Resolve-DscConfigurationProperty and Test-NodeHasRole functions.
Import-Module DscConfiguration -ErrorAction Stop

configuration SampleConfiguration
{
    Import-DscResource -ModuleName StackExchangeResources
    Import-DscResource -ModuleName cWebAdministration
    Import-DscResource -ModuleName cSmbShare

    node $AllNodes.NodeName
    {
        # This is a fairly silly example, choosing a power plan based on alphabetical order.  However, it does demonstrate how
        # you can deal with potential conflicts betwee your services when they contribute a setting to the same role, and in
        # this case, 'High Performance' is "greater than" 'Balanced'.

        $PowerPlan = Resolve-DscConfigurationProperty -Node $Node -PropertyName 'BaseServerSettings\PowerPlan' -MultipleResultBehavior AllValues |
                     Sort-Object -Descending |
                     Select-Object -First 1

        PowerPlan PowerPlan
        {
            Name = $PowerPlan
        }

        if (Test-DscConfigurationPropertyExists -Node $Node -PropertyName 'FileServerSettings')
        {
            WindowsFeature FS-FileServer
            {
                Name   = 'FS-FileServer'
                Ensure = 'Present'
            }

            $shares = @(
                Resolve-DscConfigurationProperty -Node $Node -PropertyName FileServerSettings\Shares -MultipleResultBehavior AllValues
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

        if (Test-DscConfigurationPropertyExists -Node $Node -PropertyName WebServerSettings)
        {
            WindowsFeature Web-Server
            {
                Name   = 'Web-Server'
                Ensure = 'Present'
            }

            $websites = @(
                Resolve-DscConfigurationProperty -Node $Node -PropertyName WebServerSettings\Websites -MultipleResultBehavior AllValues
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
            # This is just to demonstrate the hierarchy of Node -> Site -> Service -> Global property resolution.

            $property1 = Resolve-DscConfigurationProperty -Node $Node -PropertyName ExampleProperty1
            $property2 = Resolve-DscConfigurationProperty -Node $Node -PropertyName ExampleProperty2
            $property3 = Resolve-DscConfigurationProperty -Node $Node -PropertyName ExampleProperty3
            $property4 = Resolve-DscConfigurationProperty -Node $Node -PropertyName ExampleProperty4

            Write-Verbose -Verbose "ExampleProperty1: $property1"
            Write-Verbose -Verbose "ExampleProperty2: $property2"
            Write-Verbose -Verbose "ExampleProperty3: $property3"
            Write-Verbose -Verbose "ExampleProperty4: $property4"
        }
    }
}

