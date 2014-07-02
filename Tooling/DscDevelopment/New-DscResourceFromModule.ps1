function New-DscResourceFromModule
{
    param 
    (
        $ModulePath
    )
    $ModuleName = Split-path $ModulePath -Leaf
    $psd1 = Join-Path $ModulePath "$ModuleName.psd1"
    $psm1 = "$ModuleName.psm1"
    New-ModuleManifest -Path $psd1 -RootModule $psm1 -Author 'Steven Murawski' -CompanyName 'Stack Exchange' -FunctionsToExport 'Get-TargetResource', 'Set-TargetResource', 'Test-TargetResource'
    New-MofFile -path $ModulePath -Verbose
}

function New-DscResourceShell
{
    param
    (
        [parameter()]
        [string]
        $Path
    )

    $ModuleName = Split-Path $Path -Leaf
    $ModuleFile = Join-Path $Path "$ModuleName.psm1"
    $ModuleFileTests = Join-Path $Path "$ModuleName.Tests.ps1"

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


