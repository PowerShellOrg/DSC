Function New-DscCompositeResource
{
    <#
        .Synopsis
            Short description of the command
        .Description
            Longer description of the command 
        .EXAMPLE
            New-DscCompositeResource -Path "C:\TestModules" -ModuleName "Wakka" -ResourceName "Foo"
        .EXAMPLE
            New-DscCompositeResource -ModuleName "Wakka" -ResourceName "Foo"
        .EXAMPLE
            "Foo","Bar","Baz" | New-DscCompositeResource -ModuleName "Wakka"
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path = "$($env:ProgramFiles)\WindowsPowerShell\Modules",
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ModuleName,
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $ResourceName,
        [string]
        $Author = $env:USERNAME,
        [string]
        $Company = "Unknown",
        $Copyright = "(c) $([DateTime]::Now.Year) $env:USERNAME. All rights reserved.",
        [switch]
        $Force
    )
    begin
    {
        $admin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
        if(-not $admin -and $Path -eq "$env:ProgramFiles\WindowsPowerShell\Modules"){
            throw "Must be in Administrative context to write to $Path"
        }
         
        $rootModule     = Join-Path $Path $ModuleName
        Write-Verbose "Root module path - $RootModule"
        
        $rootModulePSD  = Join-Path $rootModule "$($moduleName).psd1" 
        Write-Verbose "Root module metadata file - $rootModulePSD"
        
        $rootModulePath = Join-Path $rootModule "DSCResources"
        Write-Verbose "DSCResources folder path $rootModulePath"

        if (-not (test-path $rootModulePSD)) {
            if($PSCmdlet.ShouldProcess($rootModule, 'Creating a base module to host DSC Resources')) { 
                New-Item -ItemType Directory -Path $rootModule -Force:$Force  | Out-Null
                New-ModuleManifest -Path $rootModulePSD -ModuleVersion '1.0.0' -Author $Author -CompanyName $Company -Description "CompositeResource Main module" -Copyright $Copyright
            }    
        }
        else {
            Write-Verbose "Module and manifest already exist at $rootModulePSD"
        }
        
        if (-not (test-path $rootModulePath) ) {
            if($PSCmdlet.ShouldProcess($rootModulePath, 'Creating the DSCResources directory')) {                    
                New-Item -ItemType Directory -Path $rootModulePath -Force:$Force  | Out-Null
            }
        }
        else {
            Write-Verbose "DSCResources folder already exists at $rootModulePath"
        }
    }
    process
    {
        $resourceFolder  = Join-Path $rootModulePath $ResourceName
        $resourcePSMName = "$($ResourceName).schema.psm1"
        $resourcePSM     = Join-Path $resourceFolder $resourcePSMName
        $resourcePSD     = Join-Path $resourceFolder "$($ResourceName).psd1"
        
        if($PSCmdlet.ShouldProcess($resourceFolder, "Creating new resource $ResourceName"))
        { 
            New-Item -ItemType Directory -Path $resourceFolder -Force:$Force  | Out-Null
            
            if ((-not (test-path $resourcePSM)) -or ($force)) { 
                New-Item -ItemType File -Path $resourcePSM -Force:$Force | Out-Null
                Add-Content -Path $resourcePSM -Value "Configuration $ResourceName`r`n{`r`n}"
            }
            if ((-not (test-path $resourcePSD)) -or ($force)) { 
                New-ModuleManifest -Path $resourcePSD -RootModule $resourcePSMName -ModuleVersion '1.0.0' -Author $Author -CompanyName $Company -Copyright $Copyright
            }

        }
        
    }

}

