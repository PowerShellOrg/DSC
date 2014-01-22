configuration Sample_cIPAddress_FixedValue
{
    param
    (
        [string[]]$NodeName = 'localhost'
    )

    Import-DscResource -Module cNetworking

    Node $NodeName
    {
        cIPAddress NewIPAddress
        {
            IPAddress      = "2001:4898:200:7:6c71:a102:ebd8:f482"
            InterfaceAlias = "Ethernet"
            SubnetMask     = 24
            AddressFamily  = "IPV6"
        }
    }
}