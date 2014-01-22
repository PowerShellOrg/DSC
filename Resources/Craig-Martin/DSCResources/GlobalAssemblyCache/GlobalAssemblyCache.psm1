<#
.Synopsys
The Get-TargetResource cmdlet.
#>
function Get-TargetResource
{
    param
    (
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [System.String]
        $Version
    )

    $gac = Get-GacAssembly -Name $Name -Version $Version

    if ($gac -ne $null)
    {
        return @{
            Ensure  = "Present";
            Name    = $gac.Name
            Version = $gac.Version
        }
    }
    else
    {
        return @{
            Ensure  = "Absent";
            Name    = $Name
            Version = $Version
        }
    }
}

<#
.Synopsys
The Set-TargetResource cmdlet.
#>
function Set-TargetResource
{    
    param
    (
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [System.String]
        $Version,

        [ValidateNotNullOrEmpty()]
        [System.String]
        $AssemblyFile
    )

    $gac = Get-GacAssembly -Name $Name -Version $Version

    if ($Ensure -eq 'Present')
    {
        Write-Verbose "Ensure -eq 'Present'"
        if ($gac -eq $null)
        {
            Write-Verbose "GAC item is missing, so adding it: $AssemblyFile"
            Add-GacAssembly -Path $AssemblyFile
        }
    }
    elseif($Ensure -eq 'Absent')
    {
        Write-Verbose "Ensure -eq 'Absent'"
        if ($gac -ne $null)
        {
            Write-Verbose "GAC item is present, so removing it: $Name"
            $gac | Remove-GacAssembly
        }
    }
}

<#
.Synopsys
The Test-TargetResource cmdlet is used to validate if the resource is in a state as expected in the instance document.
#>
function Test-TargetResource
{
    param
    (
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [System.String]
        $Version,

        [ValidateNotNullOrEmpty()]
        [System.String]
        $AssemblyFile
    )

    $gac = Get-GacAssembly -Name $Name -Version $Version

    if ($Ensure -eq 'Present')
    {
        if ($gac -eq $null)
        {
            return $false
        }
        else
        {
            return $true
        }
    }
    elseif($Ensure -eq 'Absent')
    {
        if ($gac -ne $null)
        {
            return $false
        }
        else
        {
            return $true
        }
    }

    if (Test-Path $AssemblyFile)
    {
        return $true
    }
}
