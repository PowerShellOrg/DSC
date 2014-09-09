$ApertureLabs = 'ApertureLabs-8', 'ApertureLabs-V'

Configuration ImaginaryIPv6
{
    param
    (
        [string[]]$computers = $ApertureLabs
    )

    Import-DscResource -Module cImaginaryIPv6

    Node $computers
    {
        cImaginaryIPv6 No6Imaginationland
        {
           SixToFour = "Default"
           Teredo = "Default"
           ISATAP = "Default"
        }
    } #Node
}

ImaginaryIPv6 -OutputPath d:\tmp
Start-DscConfiguration -ComputerName $ApertureLabs -Path d:\tmp -Wait -Verbose

Write-Host -BackgroundColor Magenta "Invoking Get-DscConfiguration on $ApertureLabs"
Get-DscConfiguration -CimSession $ApertureLabs -Verbose

foreach ($computer in $ApertureLabs)
{
    Write-Host -BackgroundColor Green "Invoking Test-DscConfiguration on $computer"
    Test-DscConfiguration -CimSession $computer -Verbose
}