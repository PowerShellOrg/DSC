function Get-ModuleVersion
{
    param (
        [parameter(mandatory)]
        [validatenotnullorempty()]
        [string]
        $path,
        [switch]
        $asVersion
    )
    $ModuleName = split-path $path -Leaf
    $ModulePSD1 = join-path $path "$ModuleName.psd1"

    Write-Verbose ''
    Write-Verbose "Checking for $ModulePSD1"
    if (Test-Path $ModulePSD1)
    {
        $hashtable = Import-DataFile -Path $ModulePSD1
        $Version = $hashtable['ModuleVersion']
        Write-Verbose "Found version $Version for $ModuleName."
        Write-Verbose ''
        if ($asVersion) {
            [Version]::parse($Version)
        }
        else {
            return $Version
        }
    }
    else
    {
        Write-Warning "Could not find a PSD1 for $modulename at $ModulePSD1."
    }
}


function Get-ModuleAuthor
{
    param (
        [parameter(mandatory)]
        [validatenotnullorempty()]
        [string]
        $path
    )
    $ModuleName = split-path $path -Leaf
    $ModulePSD1 = join-path $path "$ModuleName.psd1"

    if (Test-Path $ModulePSD1)
    {
        $hashtable = Import-DataFile -Path $ModulePSD1
        $Author = $hashtable['Author']
        Write-Verbose "Found author $Author for $ModuleName."
        return $Author
    }
    else
    {
        Write-Warning "Could not find a PSD1 for $modulename at $ModulePSD1."
    }
}

New-Alias -Name Get-DscResourceVersion -Value Get-ModuleVersion -Force


function Test-ModuleVersion {
    param (
        [parameter(ValueFromPipeline, Mandatory)]
        [object]
        $InputObject,
        [parameter(Mandatory, position = 0)]
        [string]
        $Destination
    )
    process {
        $DestinationModule = join-path $Destination $InputObject.name

        if (test-path $DestinationModule) {
            $CurrentModuleVersion = Get-ModuleVersion -Path $DestinationModule -asVersion
            $NewModuleVersion = Get-ModuleVersion -Path $InputObject.fullname -asVersion
            if (($CurrentModuleVersion -eq $null) -or ($NewModuleVersion -gt $CurrentModuleVersion)) {
                Write-Verbose "New module version is higher the the currently deployed module.  Replacing it."
                $InputObject
            }
            else {
                Write-Verbose "The current module is the same version or newer than the one in source control.  Not replacing it."
            }
        }
        else {
            Write-Verbose "No existing module at $DestinationModule."
            $InputObject
        }
    }

}

function Import-DataFile
{
    param (
        [Parameter(Mandatory)]
        [string] $Path
    )

    try
    {
        $content = Get-Content -Path $path -Raw -ErrorAction Stop
        $scriptBlock = [scriptblock]::Create($content)

        [string[]] $allowedCommands = @(
            'Import-LocalizedData', 'ConvertFrom-StringData', 'Write-Host', 'Out-Host', 'Join-Path'
        )

        [string[]] $allowedVariables = @('PSScriptRoot')

        $scriptBlock.CheckRestrictedLanguage($allowedCommands, $allowedVariables, $true)

        return & $scriptBlock
    }
    catch
    {
        throw
    }
}
