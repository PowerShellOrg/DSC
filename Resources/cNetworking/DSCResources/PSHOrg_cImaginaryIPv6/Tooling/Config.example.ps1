$ApertureLabs = 'ApertureLabs-8', 'ApertureLabs-V'

Configuration ImaginaryIPv6
{
    param
    (
        [string[]]$computers = $ApertureLabs
    )

    Import-DscResource -Module cNetworking

    Node $computers
    {
        cImaginaryIPv6 Imaginationland
        {
           SixToFour = "Disabled"
              Teredo = "Disabled"
              ISATAP = "Disabled"
        }
    } #Node
}

$MOFpath = 'c:\tmp\MOF'
cd $MOFpath

ImaginaryIPv6 -OutputPath $MOFpath
Start-DscConfiguration -ComputerName $ApertureLabs -Path $MOFpath -Wait -Verbose

Write-Host -BackgroundColor Magenta "Invoking Get-DscConfiguration on $ApertureLabs"
Get-DscConfiguration -CimSession $ApertureLabs -Verbose

foreach ($computer in $ApertureLabs)
{
    Write-Host -BackgroundColor Green "Invoking Test-DscConfiguration on $computer"
    Test-DscConfiguration -CimSession $computer -Verbose
}