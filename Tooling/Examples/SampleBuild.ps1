end
{
    Import-Module Pester -ErrorAction Stop
    Import-Module dscbuild -ErrorAction Stop
    Import-Module dscconfiguration -ErrorAction Stop

    $params = @{
        WorkingDirectory = (Get-TempDirectory).FullName
        SourceResourceDirectory = "$PSScriptRoot\DSC_Resources"
        SourceToolDirectory = "$PSScriptRoot\DSC_Tooling"
        DestinationRootDirectory = "$PSScriptRoot\BuldOutput"
        DestinationToolDirectory = $env:TEMP
        ConfigurationData = Get-DscConfigurationData -Path "$PSScriptRoot\DSC_Configuration" -Force -verbose
        ModulePath = "$PSScriptRoot\DSC_Script" , "$PSScriptRoot\DSC_Tooling"
        ConfigurationModuleName = 'SampleConfiguration'
        ConfigurationName = 'SampleConfiguration'
        Configuration = $true
        Resource = $true
    }

    Invoke-DscBuild @params -verbose
}

begin
{
    function Get-TempDirectory
    {
        [CmdletBinding()]
        [OutputType([System.IO.DirectoryInfo])]
        param ( )

        do
        {
            $tempDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.IO.Path]::GetRandomFileName())
        }
        until (-not (Test-Path -Path $tempDir -PathType Container))

        return New-Item -Path $tempDir -ItemType Directory -ErrorAction Stop
    }
}
