function New-DscResourceFromModule
{
    param
    (
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [parameter(Position = 0, Mandatory = $true)]
        [string] $ModulePath,
        [string] $Author,
        [string] $CompanyName
    )
    $ModuleName = Split-Path -Path $ModulePath -Leaf
    $psd1 = Join-Path -Path $ModulePath -ChildPath "$ModuleName.psd1"
    $psm1 = "$ModuleName.psm1"
    New-ModuleManifest -Path $psd1 -RootModule $psm1 -Author $Author -CompanyName $CompanyName -FunctionsToExport 'Get-TargetResource', 'Set-TargetResource', 'Test-TargetResource'
    New-MofFile -Path $ModulePath -Verbose
}

function New-DscResourceShell
{
    param
    (
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [parameter(Position = 0, Mandatory = $true)]
        [string] $Path
    )

    $ModuleName = Split-Path -Path $Path -Leaf
    $ModuleFile = Join-Path -Path $Path -ChildPath "$ModuleName.psm1"
    $ModuleFileTests = Join-Path -Path $Path -ChildPath "$ModuleName.Tests.ps1"

    if (-not (Test-Path $Path))
    {
        mkdir $Path
    }
    if (-not (Test-Path $ModuleFile))
    {
        Write-Verbose "Copying template for the module from $PSScriptRoot\DscResourceTemplate.psm1."
        Write-Verbose "`tto $ModuleFile"
        Copy-Item -Path "$PSScriptRoot\DscResourceTemplate.psm1" -Destination $ModuleFile -Force
    }
    if (-not (Test-Path $ModuleFileTests))
    {
        Write-Verbose "Copying template for the module tests from $PSScriptRoot\DscResourceTemplate.Tests.ps1."
        Write-Verbose "`tto $ModuleFileTests"
        Copy-Item -Path "$PSScriptRoot\DscResourceTemplate.Tests.ps1" -Destination $ModuleFileTests -Force
    }
}