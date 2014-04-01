function Get-DscResourceVersion
{
    param ([string]$path)
    $ModuleName = split-path $path -Leaf
    $ModulePSD1 = join-path $path "$ModuleName.psd1"
    
    if (Test-Path $ModulePSD1)
    {
        $psd1 = get-content $ModulePSD1 -Raw        
        $Version = (Invoke-Expression -Command $psd1)['ModuleVersion']
        Write-Verbose "Found version $Version for $ModuleName."
    }
    else
    {
        Write-Warning "Could not find a PSD1 for $modulename at $ModulePSD1."
    }

    return $Version
}
