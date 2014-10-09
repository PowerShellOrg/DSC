configuration SYSTEMHOSTINGConfiguration {

    Import-DscResource -ModuleName SYSTEMHOSTING 

    Node 'localhost' {

        # The properties available for use in *-NetAdapterAdvancedProperty depends entirely on the network adapter driver. Some drivers offer different features.
        # To get a full list of supported properties on your network adapter, run the following command:
        #   Get-NetAdapter -InterfaceAlias 'Ethernet' | Get-NetAdapterAdvancedProperty | Format-Table DisplayName, RegistryKeyword, RegistryValue, ValidRegistryValues
        
        cNetAdapterAdvancedProperty JumboPacket {
            InterfaceAlias = 'Ethernet'
            RegistryKeyword = '*JumboPacket'
            RegistryValue = '4088'
        }
        cNetAdapterAdvancedProperty RSS {
            InterfaceAlias = 'Ethernet'
            RegistryKeyword = '*RSS'
            RegistryValue = '1'
        }

        cNetAdapterAdvancedProperty NumRssQueues {
            InterfaceAlias = 'Ethernet'
            RegistryKeyword = '*NumRssQueues'
            RegistryValue = '8'
        }


        # The bindings available for use in *-NetAdapterBinding depends on your specific setup. Some applications may add additional bindings that are not availble on a default installation.
        # To get a full list of available bindings on your network adapter, run the following command:
        #   Get-NetAdapter -InterfaceAlias 'Ethernet' | Get-NetAdapterBinding | Format-Table DisplayName, ComponentID, Enabled

        cNetAdapterBinding IPv4 {
            InterfaceAlias = 'Ethernet'
            ComponentID = 'ms_tcpip'
            Enabled = $true
        }

        cNetAdapterBinding IPv6 {
            InterfaceAlias = 'Ethernet'
            ComponentID = 'ms_tcpip6'
            Enabled = $true
        }

        cNetAdapterBinding FilePrintSharing {
            InterfaceAlias = 'Ethernet'
            ComponentID = 'ms_server'
            Enabled = $true
        }


        # The DnsClient resource uses the Windows default settings unless otherwise specified.
        # The Windows default values are:
        #   RegisterThisConnectionAddress = $true
        #   UseSuffixWhenRegistering = $false

        cDnsClient DnsClient {
            InterfaceAlias = 'Ethernet'
            RegisterThisConnectionAddress = $true
            UseSuffixWhenRegistering = $true
        }


        # Valid values for the NetBios setting are:
        #   Enabled, Disabled, Default (Enabled)

        cNetAdapterNetBios NetBios { 
            InterfaceAlias = 'Ethernet'
            NetBios = 'Default'
        }
    }
}

SYSTEMHOSTINGConfiguration -ComputerName localhost

Start-DscConfiguration -Wait -Verbose .\SYSTEMHOSTINGConfiguration -Force