Configuration NetAdapterRename
{
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]$NewName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]$MacAddress
    )

    Import-DscResource -ModuleName cNetworking

    cNetAdapterName $NewName
    {
        NewName = $NewName
        MacAddress = $MacAddress
    }
}