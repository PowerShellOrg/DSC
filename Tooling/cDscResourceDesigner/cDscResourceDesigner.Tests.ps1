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

    InModuleScope cDscResourceDesigner {
        Describe 'New-cDscResourceProperty' {
            Context 'An Array is a Key' {
                It 'Should write an error' {
                    $errorMessage = New-cDscResourceProperty -Name "SomeName" -Type "String[]" -Attribute "Key" 2>&1
                    $errorMessage | Should Be $LocalizedData.KeyArrayError
                }
            }
            Context 'Values is an Array Type' {
                Mock -ModuleName cDscResourceDesigner Test-TypeIsArray {return $true}
                It 'should throw an error' {
                    $errorMessage = New-cDscResourceProperty -Name "Ensure" -Type "String" -Attribute Write -Values "Present","Absent" -Description "Ensure Present or Absent" 2>&1
                    $errorMessage | Should Be $LocalizedData.InvalidValidateSetUsageError
                }
            }
            Context 'ValueMap is given the wrong type' {
                Mock -ModuleName cDscResourceDesigner Test-TypeIsArray {return $false}
                It 'should throw an error' {
                    $errorMessage = @()
                    $errorMessage += $localizedData.ValidateSetTypeError -f "Present","Uint8"
                    $errorMessage += $localizedData.ValidateSetTypeError -f "Absent","Uint8"

                    $returnedError = New-cDscResourceProperty -Name "Ensure" -Type "Uint8" -Attribute Write -ValueMap "Present","Absent" -Description "Ensure Present or Absent" 2>&1

                    $returnedError[0] | Should Be $errorMessage[0]
                }
            }

            Context 'Everything is passed correctly' {
                Mock -ModuleName cDscResourceDesigner Test-TypeIsArray {return $false}
                Mock -ModuleName cDscResourceDesigner Test-Name {return $true}
                $result = New-cDscResourceProperty -Name "Ensure" -Type "String" -Attribute Write -ValueMap "Present","Absent" -Description "Ensure Present or Absent"

                It 'should return the correct Name' {
                    $result.Name | Should Be "Ensure"
                }

                It 'should return the correct Type' {
                    $result.Type | Should Be "String"
                }

                It 'should return the correct Attribute' {
                    $result.Attribute | Should Be "Write"
                }

                It 'should return the correct ValidateSet' {
                    $result.ValueMap | Should Be @("Present", "Absent")
                }

                It 'should return the correct Description' {
                    $result.Description | Should Be "Ensure Present or Absent"
                }
            }
        }

        Describe 'Test-Name' {
            Context 'Passed a bad name' {
                It 'should return the correct property error text' {
                    $errorMessage = $LocalizedData.InvalidPropertyNameError -f "123"
                    { $result = Test-Name "123" "Property" } | Should Throw $errorMessage;
                }

                It 'should return the correct resource error text' {
                    $errorMessage = $LocalizedData.InvalidResourceNameError -f "123"
                    { $result = Test-Name "123" "Resource"; } | Should Throw $errorMessage;
                }
            }

            Context 'Passed a name that was to long' {
                $name = 'a' * 256;
                It 'should return the correct property error text' {
                    $errorMessage = $LocalizedData.PropertyNameTooLongError -f $name;
                    { $result = Test-Name $name "Property" } | Should throw $errorMessage;
                }

                It 'should return the correct resource error text' {
                    $errorMessage = $LocalizedData.ResourceNameTooLongError -f $name;
                    { $result = Test-Name $name "Resource" } | Should throw $errorMessage;
                }
            }
        }

        Describe 'Test-PropertiesForResource' {
            Context 'No Key is passed' {
                It 'should throw an error' {
                    $dscProperty = [DscResourceProperty] @{
                        Name = "Ensure"
                        Type = "String"
                        Attribute = [DscResourcePropertyAttribute]::Write
                        ValueMap = @("Present", "Absent")
                        Description = "Ensure Present or Absent"
                        ContainsEmbeddedInstance = $false;
                    }

                    {Test-PropertiesForResource -Properties $dscProperty } | Should throw $LocalizedData.NoKeyError
                }
            }

            Context 'a non-unique name is passed' {
                $dscProperty = [DscResourceProperty] @{
                        Name = "Ensure"
                        Type = "String"
                        Attribute = [DscResourcePropertyAttribute]::Key
                        ValueMap = @("Present", "Absent")
                        Description = "Ensure Present or Absent"
                        ContainsEmbeddedInstance = $false;
                    }
                $dscPropertyArray = @($dscProperty, $dscProperty)

                It 'should throw a non-unique name error' {
                    $errorMessage = $localizedData.NonUniqueNameError -f "Ensure";
                    {Test-PropertiesForResource -Properties $dscPropertyArray } | Should throw $errorMessage
                }
            }

            Context 'a unique name is passed' {
                $dscProperty = [DscResourceProperty] @{
                    Name = "Ensure"
                    Type = "String"
                    Attribute = [DscResourcePropertyAttribute]::Key
                    ValueMap = @("Present", "Absent")
                    Description = "Ensure Present or Absent"
                    ContainsEmbeddedInstance = $false;
                }

                It 'should return true' {
                    Test-PropertiesForResource -Properties $dscProperty | Should Be $true
                }
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