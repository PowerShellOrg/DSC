#requires -RunAsAdministrator
# Test-cDscResource requires administrator privileges, so we may as well enforce that here.

end
{
    Remove-Module [c]DscResourceDesigner -Force
    Import-Module $PSScriptRoot\cDscResourceDesigner.psd1 -ErrorAction Stop

    Describe Test-cDscResource {
        Context 'A module with a psm1 file but no matching schema.mof' {
            Setup -Dir TestResource
            Setup -File TestResource\TestResource.ps1m -Content (Get-TestDscResourceModuleContent)

            $result = Test-cDscResource -Name $TestDrive\TestResource *>&1

            It 'should throw the correct error' {
                $result[0].FullyQualifiedErrorID | Should Be 'SchemaNotFoundInDirectoryError,Test-ResourcePath'
            }

            It 'Should fail the test' {
                # This should always be the last thing returned.
                $result[-1] | Should Be $false
            }
        }

        Context 'A module with a schema.mof file but no psm1 file' {
            Setup -Dir TestResource
            Setup -File TestResource\TestResource.schema.mof -Content (Get-TestDscResourceSchemaContent)

            $result = Test-cDscResource -Name $TestDrive\TestResource *>&1

            It 'should write the correct error' {
                $result[0].FullyQualifiedErrorID | Should Be 'ModuleNotFoundInDirectoryError,Test-ResourcePath'
            }

            It 'Should fail the test' {
                $result[1] | Should Be $false
            }
        }

        Context 'A resource with both required files, valid contents' {
            Setup -Dir TestResource
            Setup -File TestResource\TestResource.schema.mof -Content (Get-TestDscResourceSchemaContent)
            Setup -File TestResource\TestResource.psm1 -Content (Get-TestDscResourceModuleContent)

            It 'Should pass the test' {
                Test-cDscResource -Name $TestDrive\TestResource | Should Be $true
            }
        }
    }
}

begin
{
    function Get-TestDscResourceModuleContent
    {
        $content = @'
            function Get-TargetResource
            {
                [OutputType([hashtable])]
                [CmdletBinding()]
                param (
                    [Parameter(Mandatory)]
                    [string] $KeyProperty,

                    [Parameter(Mandatory)]
                    [string] $RequiredProperty
                )

                return @{
                    KeyProperty      = $KeyProperty
                    RequiredProperty = 'Required Property'
                    WriteProperty    = 'Write Property'
                    ReadProperty     = 'Read Property'
                }
            }

            function Set-TargetResource
            {
                [CmdletBinding()]
                param (
                    [Parameter(Mandatory)]
                    [string] $KeyProperty,

                    [Parameter(Mandatory)]
                    [string] $RequiredProperty,

                    [string] $WriteProperty
                )
            }

            function Test-TargetResource
            {
                [OutputType([bool])]
                [CmdletBinding()]
                param (
                    [Parameter(Mandatory)]
                    [string] $KeyProperty,

                    [Parameter(Mandatory)]
                    [string] $RequiredProperty,

                    [string] $WriteProperty
                )

                return $false
            }
'@

        return $content
    }

    function Get-TestDscResourceSchemaContent
    {
        $content = @'
[ClassVersion("1.0.0"), FriendlyName("cTestResource")]
class TestResource : OMI_BaseResource
{
    [Key] string KeyProperty;
    [required] string RequiredProperty;
    [write] string WriteProperty;
    [read] string ReadProperty;
};
'@

    return $content
    }
}