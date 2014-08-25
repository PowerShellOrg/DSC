function Test-DscConfigurationPropertyExists
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [hashtable] $Node,

        [Parameter(Mandatory)]
        [string] $PropertyName,

        [hashtable] $ConfigurationData
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

    $notFound = New-Object object
    $resolved = Resolve-DscConfigurationProperty -Node $Node -PropertyName $PropertyName -MultipleResultBehavior AllValues -ConfigurationData $ConfigurationData -DefaultValue $notFound

    return $notFound -ne $resolved
}

Set-Alias -Name Test-ConfigurationPropertyExists -Value Test-DscConfigurationPropertyExists