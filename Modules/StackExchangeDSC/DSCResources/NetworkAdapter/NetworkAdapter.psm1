# Fallback message strings in en-US
DATA localizedData
{
    # same as culture = "en-US"
    ConvertFrom-StringData @"
"@
}

if (Test-Path $PSScriptRoot\en-us)
{
    Import-LocalizedData LocalizedData -filename "$(Split-Path $PSScriptRoot -Leaf)Provider.psd1"
}

function Get-TargetResource
{
    [OutputType([Hashtable])]
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Description,
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )
    
    #Needs to return a hashtable that returns the current
    #status of the configuration component
    $Adapter = Get-NetAdapter -InterfaceDescription $Description
    if (($Adapter.Name -like $Name) -and ($Adapter.InterfaceDescription -like $Description))
    {
        $Ensure = 'Present'
    }
    else
    {
        $Ensure = 'Absent'
    }

    $Configuration = @{
        Name = $Name
        Ensure = $Ensure
        Description = $Description
    }

    return $Configuration
}

function Set-TargetResource
{
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Description,
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )
    if ($Ensure -like 'Present')
    {
        Write-Verbose "Renaming $Description to $Name and enabling the adapter."
        $Preexisting = Get-NetAdapter -Name $Name
        if ($Preexisting)
        {
            $TempName = "Temp-$(Get-Random -min 1 -max 100)"
            $Preexisting | Rename-NetAdapter -NewName $TempName -Confirm:$false
        }
        Get-Netadapter -InterfaceDescription $Description | 
            Rename-NetAdapter -NewName $Name -confirm:$false -PassThru | 
            Enable-NetAdapter -Confirm:$false
    }
    else
    {
        Write-Verbose "Renaming $Description to $Name and disabling the adapter."
        Get-Netadapter -InterfaceDescription $Description | 
            Rename-NetAdapter -NewName $Name -confirm:$false -PassThru | 
            Disable-NetAdapter  -confirm:$false
    }
}

function Test-TargetResource
{
    [OutputType([boolean])]
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Description,
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )
    $IsValid = $false
    $Adapter = Get-NetAdapter -InterfaceDescription $Description -Verbose
    if ($Ensure -like 'Present')
    {        
        if (($Adapter -ne $null) -and ($Adapter.Name -like $Name))
        {            
            if (('Up','Disconnected') -contains $Adapter.Status)
            {
                Write-Verbose "Network Adapter $Name is named correctly and $($Adapter.Status)."
                $IsValid = $true
            }
            Write-Verbose "Network Adapter $Name is named correctly and $($Adapter.Status). It should be up or disconnected."
        }
        elseif ($Adapter -eq $null)
        {
            Write-Verbose "No adapter matching that description."
            Write-Error "No adapter matching that description."
        }
        else 
        {
            Write-Verbose "$($Adapter.Name) is incorrect."
        }
    }
    else
    {
        if (($Adapter -ne $null) -and ($Adapter.Name -like $Name))
        {
            if (('Disabled', 'Disconnected') -contains $Adapter.Status)
            {
                Write-Verbose "Network Adapter $Name is named correctly and $($Adapter.Status)."
                $IsValid = $true
            }
            Write-Verbose "Network Adapter $Name is named correctly and $($Adapter.Status). It should be down or disconnected."
        }
        elseif ($Adapter -eq $null)
        {
            Write-Verbose "No adapter matching that description."
            Write-Error "No adapter matching that description."
        }
        else
        {
            Write-Verbose "$($Adapter.Name) is incorrect."
        }
    }
    
    return $IsValid
}