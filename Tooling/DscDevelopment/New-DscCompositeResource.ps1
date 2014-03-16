Function New-xDscCompositeResource
{
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
        [switch]
        $Force
    )
    begin
    {
        $admin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
        if(-not $admin -and $Path -eq "$env:ProgramFiles\WindowsPowerShell\Modules"){
            throw "Must be in Administrative context to write to $Path"
        }
        #$PSBoundParameters.Remove('Force') | Out-Null            
        $PSBoundParameters.Remove('Path') | Out-Null            
        $PSBoundParameters.Confirm = $false

        # $env:ProgramFiles\WindowsPowerShell\Modules\FooExample
        $rootModule     = Join-Path $Path $ModuleName
        # FooExample.psm1
        $rootModuleName = "$($moduleName).psm1"
        # FooExample.psd1
        $rootModuleData = "$($moduleName).psd1" 
        # $env:ProgramFiles\WindowsPowerShell\Modules\FooExample\FooExample.psm1
        $rootModulePSM  = Join-Path $rootModule $rootModuleName
        # $env:ProgramFiles\WindowsPowerShell\Modules\FooExample\FooExample.psd1
        $rootModulePSD  = Join-Path $rootModule $rootModuleData
        # $env:ProgramFiles\WindowsPowerShell\Modules\FooExample\DSCResources
        $rootModulePath = Join-Path $rootModule "DSCResources"
    }
    process
    {
        
        if($PSCmdlet.ShouldProcess($rootModulePath)){ New-Item -ItemType Directory -Path $rootModulePath -Force:$Force }
        New-Item -ItemType File -Path $rootModulePSM -Force:$Force
        New-ModuleManifest -Path $rootModulePSD -RootModule $rootModuleName

        $resourceFolder  = Join-Path $rootModulePath $ResourceName
        $resourcePSMName = "$($ResourceName).schema.psm1"
        $resourcePSM     = Join-Path $resourceFolder $resourcePSMName
        $resourcePSD     = Join-Path $resourceFolder "$($ResourceName).psd1"
        
        if($PSCmdlet.ShouldProcess($resourceFolder)){ New-Item -ItemType Directory -Path $resourceFolder -Force:$Force }
        New-Item -ItemType File -Path $resourcePSM -Force:$Force
        New-ModuleManifest -Path $resourcePSD -RootModule $resourcePSMName
    }
<#
.EXAMPLE
New-xDscCompositeResource -Path "C:\TestModules" -ModuleName "Wakka" -ResourceName "Foo"
.EXAMPLE
New-xDscCompositeResource -ModuleName "Wakka" -ResourceName "Foo"
.EXAMPLE
"Foo","Bar","Baz" | New-xDscCompositeResource -ModuleName "Wakka"
#>
}