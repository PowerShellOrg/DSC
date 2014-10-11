end
{
    Import-Module Pester -ErrorAction Stop
    Import-Module dscbuild -ErrorAction Stop
    Import-Module dscconfiguration -ErrorAction Stop

    $params = @{
        WorkingDirectory = (Get-TempDirectory).FullName
        SourceResourceDirectory = "$PSScriptRoot\DSC_Resources"
        SourceToolDirectory = "$PSScriptRoot\DSC_Tooling"
        DestinationRootDirectory = 'C:\Program Files\WindowsPowerShell\DscService'
        DestinationToolDirectory = $env:TEMP
        ConfigurationData = Get-DscConfigurationData -Path .\DSC_Configuration -Force
        ConfigurationModuleName = 'SampleConfiguration'
        ConfigurationName = 'SampleConfiguration'
        Configuration = $true
        Resource = $true
    }

    Invoke-DscBuild @params
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
