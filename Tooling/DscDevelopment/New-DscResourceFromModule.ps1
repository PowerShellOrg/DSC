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
