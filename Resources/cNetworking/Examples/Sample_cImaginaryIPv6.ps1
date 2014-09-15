# Sample configuration for cImaginaryIPv6 DSC Resource
# Description: Enable/Disable IPv6 Transition Mechanism: 6to4, Teredo, ISATAP
# Feedback/jinx to: foo@snobu.org / @evilSnobu
# Windows 8+ / Windows Server 2012+ only

Configuration Sample_ImaginaryIPv6
{
    param
    (
        [string[]]$NodeName = 'localhost'
        <#
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Default","Enabled","Disabled")]
        [String]$SixToFour,
        
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Automatic","Client","Default","Disabled","Enterpriseclient","Server")]
        [String]$Teredo,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Default","Enabled","Disabled")]
        [String]$ISATAP
        #>
	)

    Import-DscResource -Module cNetworking

    Node $NodeName
    {
        cImaginaryIPv6 Imaginationland
        {
           SixToFour = "Disabled"
              Teredo = "Disabled"
              ISATAP = "Disabled"
        }
    } #Node
}