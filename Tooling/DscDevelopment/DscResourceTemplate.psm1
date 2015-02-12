# Fallback message strings in en-US
DATA localizedData
{
    # same as culture = "en-US"
    ConvertFrom-StringData @'
'@
}

if (Test-Path $PSScriptRoot\en-us)
{
    $ModuleName = Split-Path $PSScriptRoot -Leaf
    Import-LocalizedData LocalizedData -filename "$($ModuleName)Provider.psd1"
}

function Get-TargetResource
{
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory)]
        [string] $Name
    )

    $Configuration = @{
        Name = $Name
        Ensure = 'Absent'
    }

    return $Configuration
}

function Set-TargetResource
{
    param (
        [Parameter(Mandatory)]
        [string] $Name,

        [ValidateSet('Present','Absent')]
        [string] $Ensure = 'Present'
    )


}

function Test-TargetResource
{
    [OutputType([bool])]
    param (
        [Parameter(Mandatory)]
        [string] $Name,

        [ValidateSet('Present','Absent')]
        [string] $Ensure = 'Present'
    )

    #Needs to return a boolean
    return $true
}

Export-ModuleMember Get-TargetResource, Test-TargetResource, Set-TargetResource
