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
                    $errorMessage = New-cDscResourceProperty -Name 'SomeName' -Type 'String[]' -Attribute 'Key' 2>&1
                    $errorMessage | Should Be $LocalizedData.KeyArrayError
                }
            }
            Context 'Values is an Array Type' {
                Mock -ModuleName cDscResourceDesigner Test-TypeIsArray {
                    return $true
                }
                It 'should throw an error' {
                    $errorMessage = New-cDscResourceProperty -Name 'Ensure' -Type 'String' -Attribute Write -Values 'Present', 'Absent' -Description 'Ensure Present or Absent' 2>&1
                    $errorMessage | Should Be $LocalizedData.InvalidValidateSetUsageError
                }
            }
            Context 'ValueMap is given the wrong type' {
                Mock -ModuleName cDscResourceDesigner Test-TypeIsArray {
                    return $false
                }
                It 'should throw an error' {
                    $errorMessage = @()
                    $errorMessage += $LocalizedData.ValidateSetTypeError -f 'Present', 'Uint8'
                    $errorMessage += $LocalizedData.ValidateSetTypeError -f 'Absent', 'Uint8'

                    $returnedError = New-cDscResourceProperty -Name 'Ensure' -Type 'Uint8' -Attribute Write -ValueMap 'Present', 'Absent' -Description 'Ensure Present or Absent' 2>&1

                    $returnedError[0] | Should Be $errorMessage[0]
                }
            }

            Context 'Everything is passed correctly' {
                Mock -ModuleName cDscResourceDesigner Test-TypeIsArray {
                    return $false
                }
                Mock -ModuleName cDscResourceDesigner Test-Name {
                    return $true
                }
                $result = New-cDscResourceProperty -Name 'Ensure' -Type 'String' -Attribute Write -ValueMap 'Present', 'Absent' -Description 'Ensure Present or Absent'

                It 'should return the correct Name' {
                    $result.Name | Should Be 'Ensure'
                }

                It 'should return the correct Type' {
                    $result.Type | Should Be 'String'
                }

                It 'should return the correct Attribute' {
                    $result.Attribute | Should Be 'Write'
                }

                It 'should return the correct ValidateSet' {
                    $result.ValueMap | Should Be @('Present', 'Absent')
                }

                It 'should return the correct Description' {
                    $result.Description | Should Be 'Ensure Present or Absent'
                }
            }
        }

        Describe 'Test-Name' {
            Context 'Passed a bad name' {
                It 'should return the correct property error text' {
                    $errorMessage = $LocalizedData.InvalidPropertyNameError -f '123'
                    {
                        $result = Test-Name '123' 'Property' 
                    } | Should Throw $errorMessage
                }

                It 'should return the correct resource error text' {
                    $errorMessage = $LocalizedData.InvalidResourceNameError -f '123'
                    {
                        $result = Test-Name '123' 'Resource'
                    } | Should Throw $errorMessage
                }
            }

            Context 'Passed a name that was to long' {
                $name = 'a' * 256
                It 'should return the correct property error text' {
                    $errorMessage = $LocalizedData.PropertyNameTooLongError -f $name
                    {
                        $result = Test-Name $name 'Property' 
                    } | Should throw $errorMessage
                }

                It 'should return the correct resource error text' {
                    $errorMessage = $LocalizedData.ResourceNameTooLongError -f $name
                    {
                        $result = Test-Name $name 'Resource' 
                    } | Should throw $errorMessage
                }
            }
        }

        Describe 'Test-PropertiesForResource' {
            Context 'No Key is passed' {
                It 'should throw an error' {
                    $dscProperty = [DscResourceProperty] @{
                        Name                     = 'Ensure'
                        Type                     = 'String'
                        Attribute                = [DscResourcePropertyAttribute]::Write
                        ValueMap                 = @('Present', 'Absent')
                        Description              = 'Ensure Present or Absent'
                        ContainsEmbeddedInstance = $false
                    }

                    {
                        Test-PropertiesForResource -Properties $dscProperty 
                    } | Should throw $LocalizedData.NoKeyError
                }
            }

            Context 'a non-unique name is passed' {
                $dscProperty = [DscResourceProperty] @{
                    Name                     = 'Ensure'
                    Type                     = 'String'
                    Attribute                = [DscResourcePropertyAttribute]::Key
                    ValueMap                 = @('Present', 'Absent')
                    Description              = 'Ensure Present or Absent'
                    ContainsEmbeddedInstance = $false
                }
                $dscPropertyArray = @($dscProperty, $dscProperty)

                It 'should throw a non-unique name error' {
                    $errorMessage = $LocalizedData.NonUniqueNameError -f 'Ensure'
                    {
                        Test-PropertiesForResource -Properties $dscPropertyArray 
                    } | Should throw $errorMessage
                }
            }

            Context 'a unique name is passed' {
                $dscProperty = [DscResourceProperty] @{
                    Name                     = 'Ensure'
                    Type                     = 'String'
                    Attribute                = [DscResourcePropertyAttribute]::Key
                    ValueMap                 = @('Present', 'Absent')
                    Description              = 'Ensure Present or Absent'
                    ContainsEmbeddedInstance = $false
                }

                It 'should return true' {
                    Test-PropertiesForResource -Properties $dscProperty | Should Be $true
                }
            }
        }

        Describe 'New-cDscResource' {
            $dscProperty = [DscResourceProperty] @{
                Name                     = 'Ensure'
                Type                     = 'String'
                Attribute                = [DscResourcePropertyAttribute]::Key
                ValueMap                 = @('Present', 'Absent')
                Description              = 'Ensure Present or Absent'
                ContainsEmbeddedInstance = $false
            }

            Mock Test-Name {
                return $true
            } -Verifiable
            Mock Test-PropertiesForResource {
                return $true
            } -Verifiable
            Mock New-Item {
                Write-Error 'SomeError'
            } -Verifiable

            Context 'everything should be working' {
                Mock Test-Path {
                    return $true
                } -Verifiable
                Mock New-DscSchema {
                    return $null
                } -Verifiable
                Mock New-DscModule {
                    return $null
                } -Verifiable
                Mock Test-cDscResource {
                    return $true
                } -Verifiable

                It 'does not throw' {
                    {
                        New-cDscResource -Name 'UserResource' -Property $dscProperty -Path "$pshome\Modules\UserResource" -ClassVersion 1.0 -FriendlyName 'User' -Force 
                    } | Should Not throw
                }

                $result = New-cDscResource -Name 'UserResource' -Property $dscProperty -Path "$pshome\Modules\UserResource" -ClassVersion 1.0 -FriendlyName 'User' -Force

                It 'calls Test-PropertiesForResource ' {
                    Assert-MockCalled Test-PropertiesForResource -Times 1
                }

                It 'calls Test-Name' {
                    Assert-MockCalled Test-Name -Times 1
                }

                It 'calls Test-Path' {
                    Assert-MockCalled Test-Path
                }

                It 'calls New-DscSchema' {
                    Assert-MockCalled New-DscSchema
                }

                It 'calls New-DscModule' {
                    Assert-MockCalled New-DscModule
                }

                It 'calls Test-cDscResource' {
                    Assert-MockCalled Test-cDscResource
                }
            }

            Context 'a bad path is passed' {
                Mock Test-Path {
                    return $false 
                } -Verifiable

                It 'should throw a Path is Invalid Error' {
                    $path = 'C:\somerandompaththatdoesactuallyexistbecausethisisatest'
                    $errorMessage = ($LocalizedData.PathIsInvalidError -f $path)
                    {
                        New-cDscResource -Name 'UserResource' -Property $dscProperty -Path 'C:\somerandompaththatdoesactuallyexistbecausethisisatest' -ClassVersion 1.0 -FriendlyName 'User' -Force
                    } | Should throw $errorMessage
                }
            }

            Context 'a bad module path is passed' {
                It 'should throw a Path is invalid error' {
                    $fullPath = Join-Path -Path $pshome -ChildPath 'UserResource'
                    Mock Test-Path {
                        return $true
                    } -Verifiable
                    Mock Test-Path {
                        return $false
                    } -ParameterFilter {
                        $path -eq $fullPath -and $PathType -eq 'Container'
                    }
                    $errorMessage = ($LocalizedData.PathIsInvalidError -f $fullPath)

                    {
                        New-cDscResource -Name 'UserResource' -Property $dscProperty -Path $pshome -ModuleName 'UserResource' -ClassVersion 1.0 -FriendlyName 'User' -Force
                    } | Should throw $errorMessage
                }

                It 'should throw a Path is invalid error for the manifest' {
                    Mock Test-Path {
                        return $true
                    } -Verifiable
                    Mock Test-Path {
                        return $true
                    } -ParameterFilter {
                        $path -eq "$pshome\UserResource"
                    }
                    Mock Test-Path {
                        return $false
                    } -ParameterFilter {
                        $path -eq "$pshome\UserResource\UserResource.psd1"
                    }
                    Mock New-ModuleManifest {
                        Write-Error 'SomeError'
                    }

                    $path = "$pshome\UserResource"
                    $errorMessage = ($LocalizedData.PathIsInvalidError -f $path)

                    {
                        New-cDscResource -Name 'UserResource' -Property $dscProperty -Path $pshome -ModuleName 'UserResource' -ClassVersion 1.0 -FriendlyName 'User' -Force
                    } | Should throw $errorMessage
                }
            }

            Context 'a bad DSC Resource path is passed' {
                Mock New-Item {
                    Write-Error 'SomeError'
                } -Verifiable

                It 'should throw a Path is invalid error' {
                    $dscPath = "$pshome\UserResource\DSCResources"
                    Mock Test-Path {
                        return $true
                    } -Verifiable
                    Mock Test-Path {
                        return $false
                    } -ParamterFilter {
                        $path -eq $dscPath
                    }
                    $errorMessage = ($LocalizedData.PathIsInvalidError -f $dscPath)
                    {
                        New-cDscResource -Name 'UserResource' -Property $dscProperty -Path $dscPath -ClassVersion 1.0 -FriendlyName 'User' -Force
                    } | Should throw $errorMessage
                }
            }

            Context 'a bad DSC Resource + Name path is passed' {
                Mock New-Item {
                    Write-Error 'SomeError'
                } -Verifiable

                It 'should throw a Path is invalid error' {
                    $dscPath = "$pshome\UserResource\DSCResources"
                    Mock Test-Path {
                        return $true
                    } -Verifiable
                    Mock Test-Path {
                        return $false
                    } -ParamterFilter {
                        $path -eq $dscPath
                    }
                    $errorMessage = ($LocalizedData.PathIsInvalidError -f $dscPath)
                    {
                        New-cDscResource -Name 'UserResource' -Property $dscProperty -Path $dscPath -ClassVersion 1.0 -FriendlyName 'User' -Force
                    } | Should throw $errorMessage
                }
            }

            Context 'Test-cDscResource does not pass' {
                Mock New-DscSchema {
                    return $null
                } -Verifiable
                Mock New-DscModule {
                    return $null
                } -Verifiable
                Mock Test-cDscResource {
                    return $false
                } -Verifiable
                Mock Remove-Item {
                    return $null
                } -Verifiable
                Mock Test-Path {
                    return $true
                } -Verifiable

                It 'should throw a Path is invalid error' {
                    $dscPath = "$pshome\UserResource\DSCResources"
                    {
                        New-cDscResource -Name 'UserResource' -Property $dscProperty -Path $dscPath -ClassVersion 1.0 -FriendlyName 'User' -Force
                    } | Should throw $LocalizedData.ResourceError
                }
            }
        }

        Describe 'New-DscManifest' {
            Mock New-ModuleManifest {
                return $null
            } -Verifiable

            $result1 = New-DscManifest -Name 'UserResource' -Path $env:tmp -ClassVersion 1.0 -Force

            It 'should call all the Mocks' {
                Assert-VerifiableMocks
            }

            $result2 = New-DscManifest -Name 'UserResource' -Path $env:tmp -ClassVersion 1.0 -WhatIf *>&1

            $ManifestPath = Join-Path $env:tmp "UserResource.psd1"
            $warning = ($localizedData.ManifestNotOverWrittenWarning -f $ManifestPath)

            It 'should write a warning message' {
                $result2.Message | Should Be $warning
            }
        }

        Describe 'New-DscSchema' {
            Mock Add-StringBuilderLine { return $null } -Verifiable
            Mock Test-Path { return $true } -Verifiable
            Mock New-DscSchemaParameter {return $null} -Verifiable
            
            $dscProperty = [DscResourceProperty] @{
                Name                     = 'Ensure'
                Type                     = 'String'
                Attribute                = [DscResourcePropertyAttribute]::Key
                ValueMap                 = @('Present', 'Absent')
                Description              = 'Ensure Present or Absent'
                ContainsEmbeddedInstance = $false
            }

            $result = New-DscSchema -Name 'Test' -Path $env:temp -Parameters $dscProperty -ClassVersion 1.0 -WhatIf *>&1

            It 'should call all the Mocks' {
                Assert-VerifiableMocks
            }

            $schemaPath = Join-Path $env:tmp "Test.schema.mof"
            $warning = ($localizedData.SchemaNotOverWrittenWarning -f $SchemaPath)

            It 'Should throw a Warning' {
                $result.Message | Should Be $warning
            }
        }

        Describe 'Get-TypeNameForSchema' {
            Context 'get type Hashtable' {
                $result = Get-TypeNameForSchema -Type 'Hashtable'

                It 'should return string' {
                    $result | should be 'String'
                }
            }

            Context 'get type int32' {
                $result = Get-TypeNameForSchema -Type 'int32'

                It 'should return int32' {
                    $result | should be 'int32'
                }
            }

            Context 'get non-existant type' {
                It 'should throw an error ' {
                    {Get-TypeNameForSchema -Type Get-Random} | Should throw
                }
            }
        }

        Describe 'Test-TypeIsArray' {
            Context 'Passed a hashtable' {
                $result = Test-TypeIsArray -Type 'Int32[]'
                It 'Should return true' {
                    $result | should be $true
                }
            }

            Context 'not passed a hashtable' {
                $result = Test-TypeIsArray -Type 'String'
                it 'should return false' {
                    $result | should be $false
                }
            }
        }

        Describe 'New-DscSchemaParameter' {
            Context 'dscProperty only contains the minimum properties' {
                $dscProperty = [DscResourceProperty] @{
                    Name                     = 'Ensure'
                    Type                     = 'String'
                    Attribute                = [DscResourcePropertyAttribute]::Key
                }

                $result = New-DscSchemaParameter -Parameter $dscProperty
                $expected = "`t[Key] String Ensure;"

                It 'should return the correct string' {
                    $result | should be $expected
                }
            }

            Context 'dscProperty has an embeded instance' {
                $dscProperty = [DscResourceProperty] @{
                    Name                     = 'Ensure'
                    Type                     = 'Hashtable'
                    Attribute                = [DscResourcePropertyAttribute]::Key
                }

                $result = New-DscSchemaParameter -Parameter $dscProperty
                $expected = "`t[Key, EmbeddedInstance(`"MSFT_KeyValuePair`")] String Ensure[];"

                It 'should return the correct string' {
                    $result | should be $expected
                }
            }

            Context 'dscProperty has a Description' {
                $dscProperty = [DscResourceProperty] @{
                    Name                     = 'Ensure'
                    Type                     = 'String'
                    Attribute                = [DscResourcePropertyAttribute]::Key
                    Description              = 'Ensure Present or Absent'
                }

                $result = New-DscSchemaParameter -Parameter $dscProperty
                $expected = "`t[Key, Description(`"Ensure Present or Absent`")] String Ensure;"

                It 'should return the correct string' {
                    $result | should be $expected
                }
            }

            Context 'dscProperty has a value map' {
                $dscProperty = [DscResourceProperty] @{
                    Name        = 'Ensure'
                    Type        = 'String'
                    Attribute   = [DscResourcePropertyAttribute]::Key
                    Description = 'Ensure Present or Absent'
                    ValueMap    = @('Present', 'Absent')
                }

                $result = New-DscSchemaParameter -Parameter $dscProperty
                $expected = "`t[Key, Description(`"Ensure Present or Absent`"), ValueMap{`"Present`",`"Absent`"}] String Ensure;"

                It 'should return the correct string' {
                    $result | should be $expected
                }
            }

            Context 'dscProperty has values' {
                $dscProperty = [DscResourceProperty] @{
                    Name        = 'Ensure'
                    Type        = 'String'
                    Attribute   = [DscResourcePropertyAttribute]::Key
                    Description = 'Ensure Present or Absent'
                    ValueMap    = @('Present', 'Absent')
                    Values      = @('Present', 'Absent')
                }

                $result = New-DscSchemaParameter -Parameter $dscProperty
                $expected = "`t[Key, Description(`"Ensure Present or Absent`"), ValueMap{`"Present`",`"Absent`"}, Values{`"Present`",`"Absent`"}] String Ensure;"

                It 'should return the correct string' {
                    $result | should be $expected
                }
            }
        }

        Describe 'New-DelimitedList' {
            Context 'a list of numbers is passed in' {
                $result = New-DelimitedList -list @(1,2,3,4,5)
                $expected = '1,2,3,4,5'

                It 'should return the numbers' {
                    $result | Should Be $expected
                }
            }

            Context 'the string switch is used' {
                $result = New-DelimitedList -list @(1,2,3,4,5) -String
                $expected = '"1","2","3","4","5"'

                It 'should return the numbers wrapped in quotes' {
                    $result | Should Be $expected
                }
            }

            Context 'the seperator parameter is used' {
                $result = New-DelimitedList -list @(1,2,3,4,5) -String -Separator ';'
                $expected = '"1";"2";"3";"4";"5"'

                It 'should return the numbers wrapped in qoutes, seperated by semicolons' {
                    $result | Should Be $expected
                }
            }
        }

        Describe 'New-DscModule' {
            $dscProperty = [DscResourceProperty] @{
                Name                     = 'Ensure'
                Type                     = 'String'
                Attribute                = [DscResourcePropertyAttribute]::Key
                ValueMap                 = @('Present', 'Absent')
                Description              = 'Ensure Present or Absent'
                ContainsEmbeddedInstance = $false
            }

            Context 'writing out to a file' {
                Mock New-GetTargetResourceFunction { return $null } -Verifiable
                Mock New-SetTargetResourceFunction { return $null } -Verifiable
                Mock New-TestTargetResourceFunction { return $null } -Verifiable

                Mock Out-File { return $null } -Verifiable

                $result = New-DscModule -Name 'Test' -Path $env:temp -Parameters $dscProperty

                It 'should call all the Mocks' {
                    Assert-VerifiableMocks
                }
            }

            Context 'unable to overwrite module' {
                Mock New-GetTargetResourceFunction { return $null } -Verifiable
                Mock New-SetTargetResourceFunction { return $null } -Verifiable
                Mock New-TestTargetResourceFunction { return $null } -Verifiable

                Mock Test-Path { return $true } -Verifiable

                $result = New-DscModule -Name 'Test' -Path $env:temp -Parameters $dscProperty -WhatIf *>&1

                $ModulePath = Join-Path $env:tmp "Test.psm1"
                $warning = ($localizedData.ModuleNotOverWrittenWarning -f $ModulePath)

                It 'Should throw a Warning' {
                    $result.Message | Should Be $warning
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