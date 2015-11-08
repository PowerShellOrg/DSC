#requires -RunAsAdministrator
# Test-cDscResource requires administrator privileges, so we may as well enforce that here.

end
{
    Remove-Module [c]DscResourceDesigner -Force
    Import-Module $PSScriptRoot\cDscResourceDesigner.psd1 -ErrorAction Stop

    Describe Test-cDscResource {
        Context 'A module with a psm1 file but no matching schema.mof' {
            Setup -Dir TestResource
            Setup -File TestResource\TestResource.psm1 -Content (Get-TestDscResourceModuleContent)

            It 'Should fail the test' {
                Test-cDscResource -Name $TestDrive\TestResource | Should Be $false
            }
        }

        Context 'A module with a schema.mof file but no psm1 file' {
            Setup -Dir TestResource
            Setup -File TestResource\TestResource.schema.mof -Content (Get-TestDscResourceSchemaContent)

            It 'Should fail the test' {
                Test-cDscResource -Name $TestDrive\TestResource | Should Be $false
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

            Mock Test-Name { return $true } -Verifiable
            Mock Test-PropertiesForResource { return $true } -Verifiable
            Mock New-Item { Write-Error 'SomeError'} -Verifiable

            Context 'everything should be working' {
                Mock Test-Path { return $true } -Verifiable
                Mock New-DscSchema { return $null } -Verifiable
                Mock New-DscModule { return $null } -Verifiable
                Mock Test-cDscResource { return $true } -Verifiable

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
                Mock Test-Path { return $false } -Verifiable

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
                    $fullPath = Join-Path -Path $pshome -ChildPath 'ModuleName\DSCResources'
                    Mock Test-Path { return $true } -Verifiable
                    Mock Test-Path { return $false } -ParameterFilter { $path -eq $fullPath -and $PathType -eq 'Container' }
                    $errorMessage = ($LocalizedData.PathIsInvalidError -f $fullPath)

                    {
                        New-cDscResource -Name 'UserResource' -Property $dscProperty -Path $pshome -ModuleName 'ModuleName' -ClassVersion 1.0 -FriendlyName 'User' -Force
                    } | Should throw $errorMessage
                }

                It 'should throw a Path is invalid error for the manifest' {
                    Mock Test-Path { return $true} -Verifiable
                    Mock Test-Path { return $true } -ParameterFilter { $path -eq "$pshome\UserResource" }
                    Mock Test-Path { return $false } -ParameterFilter { $path -eq "$pshome\UserResource\UserResource.psd1" }
                    Mock New-ModuleManifest {
                        Write-Error 'SomeError'
                    }

                    $path = "$pshome\UserResource\UserResource.psd1"
                    $errorMessage = ($LocalizedData.PathIsInvalidError -f $path)

                    {
                        New-cDscResource -Name 'UserResource' -Property $dscProperty -Path $pshome -ModuleName 'UserResource' -ClassVersion 1.0 -FriendlyName 'User' -Force
                    } | Should throw $errorMessage
                }
            }

            Context 'a bad DSC Resource path is passed' {
                Mock New-Item { Write-Error 'SomeError' } -Verifiable

                It 'should throw a Path is invalid error' {
                    $dscPath = "$pshome\UserResource\DSCResources"
                    Mock Test-Path { return $true } -Verifiable
                    Mock Test-Path { return $false } -ParamterFilter { $path -eq $dscPath }
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
                    Mock Test-Path { return $true } -Verifiable
                    Mock Test-Path { return $false } -ParamterFilter { $path -eq $dscPath }
                    $errorMessage = ($LocalizedData.PathIsInvalidError -f $dscPath)
                    {
                        New-cDscResource -Name 'UserResource' -Property $dscProperty -Path $dscPath -ClassVersion 1.0 -FriendlyName 'User' -Force
                    } | Should throw $errorMessage
                }
            }

            Context 'Test-cDscResource does not pass' {
                Mock New-DscSchema { return $null } -Verifiable
                Mock New-DscModule { return $null } -Verifiable
                Mock Test-cDscResource { return $false } -Verifiable
                Mock Remove-Item { return $null } -Verifiable
                Mock Test-Path { return $true } -Verifiable

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

            Mock Test-Path {
                return $true
            } -Verifiable

            $newModuleManifestTest = New-DscManifest -Name 'UserResource' -Path $env:tmp -ClassVersion 1.0 -Force

            It 'should call New-ModuleManifest' {
                Assert-MockCalled New-ModuleManifest
            }

            $result = New-DscManifest -Name 'UserResource' -Path $env:tmp -ClassVersion 1.0 -WhatIf *>&1

            $ManifestPath = Join-Path $env:tmp "UserResource.psd1"
            $warning = ($localizedData.ManifestNotOverWrittenWarning -f $ManifestPath)

            It 'should write a warning message if file exists' {
                $result.Message | Should Be $warning
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

        Describe 'Add-StringBuilderLine' {
            $StringBuilder = New-Object -TypeName System.Text.StringBuilder
            $Line = 'Line';

            Context 'A line is passed' {
                $result = Add-StringBuilderLine -Builder $StringBuilder -Line $Line
                $expect = 'Line'

                It 'should return the correct line' {
                    $result | should be $expected
                }
            }

            Context 'No line is passed' {
                $result = Add-StringBuilderLine -Builder $StringBuilder

                $expect = $Line + [Environment]::NewLine

                It 'should return the correct line' {
                    $result | should be $expected
                }
            }

            Context 'Append is Passed' {
                $result = Add-StringBuilderLine -Builder $StringBuilder -Line $Line -Append

                $expect = $Line + [Environment]::NewLine + $Line

                It 'should return the correct line' {
                    $result | should be $expected
                }
            }
        }

        Describe 'New-TestTargetResourceFunction' {
            $dscProperty = [DscResourceProperty] @{
                Name                     = 'Ensure'
                Type                     = 'String'
                Attribute                = [DscResourcePropertyAttribute]::Key
                ValueMap                 = @('Present', 'Absent')
                Description              = 'Ensure Present or Absent'
                ContainsEmbeddedInstance = $false
            }

            $result = New-DscModuleFunction 'Test-TargetResource' ($dscProperty | Where-Object {([DscResourcePropertyAttribute]::Read -ne $_.Attribute)}) 'Boolean'` -FunctionContent $functionContent

            $expected = "function Test-TargetResource`r`n{`r`n`t[CmdletBinding()]`r`n`t[OutputType([System.Boolean])]`r`n`tparam`r`n`t(`r`n`t`t[parameter(Mandatory = `$true)]`r`n`t`t[System.String]`r`n`t`t`$Ensure`r`n`t)`r`n`r`n`t#Write-Verbose `"Use this cmdlet to deliver information about command processing.`"`r`n`r`n`t#Write-Debug `"Use this cmdlet to write debug information while troubleshooting.`"`r`n`r`n`r`n`t<#`r`n`t`$result = [System.Boolean]`r`n`t`r`n`t`$result`r`n`t#>`r`n}`r`n`r`n"

            It 'returns the correct string' {
                $result | Should Be $expected
            }
        }

        Describe 'New-GetTargetResourceFunction' {
            $dscProperty = [DscResourceProperty] @{
                Name                     = 'Ensure'
                Type                     = 'String'
                Attribute                = [DscResourcePropertyAttribute]::Key
                ValueMap                 = @('Present', 'Absent')
                Description              = 'Ensure Present or Absent'
                ContainsEmbeddedInstance = $false
            }

            $result = New-DscModuleFunction 'Get-TargetResource' ($dscProperty | Where-Object {([DscResourcePropertyAttribute]::Key -eq $_.Attribute) -or ([DscResourcePropertyAttribute]::Required -eq $_.Attribute)}) 'System.Collections.Hashtable' ($dscProperty) -FunctionContent $functionContent

            $expected = "function Get-TargetResource`r`n{`r`n`t[CmdletBinding()]`r`n`t[OutputType([System.Collections.Hashtable])]`r`n`tparam`r`n`t(`r`n`t`t[parameter(Mandatory = `$true)]`r`n`t`t[System.String]`r`n`t`t`$Ensure`r`n`t)`r`n`r`n`t#Write-Verbose `"Use this cmdlet to deliver information about command processing.`"`r`n`r`n`t#Write-Debug `"Use this cmdlet to write debug information while troubleshooting.`"`r`n`r`n`r`n`t<#`r`n`t`$returnValue = @{`r`n`t`tEnsure = [System.String]`r`n`t}`r`n`r`n`t`$returnValue`r`n`t#>`r`n}`r`n`r`n"

            It 'returns the correct string' {
                $result | Should Be $expected
            }
        }

        Describe 'New-SetTargetResourceFunction' {
            $dscProperty = [DscResourceProperty] @{
                Name                     = 'Ensure'
                Type                     = 'String'
                Attribute                = [DscResourcePropertyAttribute]::Key
                ValueMap                 = @('Present', 'Absent')
                Description              = 'Ensure Present or Absent'
                ContainsEmbeddedInstance = $false
            }

            $result = New-DscModuleFunction 'Set-TargetResource' ($dscProperty | Where-Object {([DscResourcePropertyAttribute]::Read -ne $_.Attribute)}) -FunctionContent $functionContent

            $expected = "function Set-TargetResource`r`n{`r`n`t[CmdletBinding()]`r`n`tparam`r`n`t(`r`n`t`t[parameter(Mandatory = `$true)]`r`n`t`t[System.String]`r`n`t`t`$Ensure`r`n`t)`r`n`r`n`t#Write-Verbose `"Use this cmdlet to deliver information about command processing.`"`r`n`r`n`t#Write-Debug `"Use this cmdlet to write debug information while troubleshooting.`"`r`n`r`n`t#Include this line if the resource requires a system reboot.`r`n`t#`$global:DSCMachineStatus = 1`r`n`r`n`r`n}`r`n`r`n"

            It 'returns the correct string' {
                $result | Should Be $expected
            }
        }

        Describe 'New-DscModuleFunction' {
            $dscProperty = [DscResourceProperty] @{
                Name                     = 'Ensure'
                Type                     = 'String'
                Attribute                = [DscResourcePropertyAttribute]::Key
                ValueMap                 = @('Present', 'Absent')
                Description              = 'Ensure Present or Absent'
                ContainsEmbeddedInstance = $false
            }

            Context 'Function Content is passed' {
                $result = New-DscModuleFunction -Name 'Set-TargetResource' -Parameters ($dscProperty | Where-Object {([DscResourcePropertyAttribute]::Read -ne $_.Attribute)}) -FunctionContent 'Test'

                $expected = "function Set-TargetResource`r`n{`r`n`t[CmdletBinding()]`r`n`tparam`r`n`t(`r`n`t`t[parameter(Mandatory = `$true)]`r`n`t`t[System.String]`r`n`t`t`$Ensure`r`n`t)`r`nTest`r`n}`r`n"

                It 'should return the funciton content' {
                    $result | should be $expected
                }
            }

            Context 'Return Type is Passed' {
                $result = New-DscModuleFunction -Name 'Set-TargetResource' -Parameters ($dscProperty | Where-Object {([DscResourcePropertyAttribute]::Read -ne $_.Attribute)}) -FunctionContent 'Test' -ReturnType 'Boolean'
                $expected = "function Set-TargetResource`r`n{`r`n`t[CmdletBinding()]`r`n`t[OutputType([System.Boolean])]`r`n`tparam`r`n`t(`r`n`t`t[parameter(Mandatory = `$true)]`r`n`t`t[System.String]`r`n`t`t`$Ensure`r`n`t)`r`nTest`r`n}`r`n"

                It 'should return the return type' {
                    $result | Should Be $expected
                }
            }

            Context 'No Function Content is passed' {
                $result = New-DscModuleFunction -Name 'Set-TargetResource' -Parameters ($dscProperty | Where-Object {([DscResourcePropertyAttribute]::Read -ne $_.Attribute)}) -ReturnType 'Boolean'

                $expected = "function Set-TargetResource`r`n{`r`n`t[CmdletBinding()]`r`n`t[OutputType([System.Boolean])]`r`n`tparam`r`n`t(`r`n`t`t[parameter(Mandatory = `$true)]`r`n`t`t[System.String]`r`n`t`t`$Ensure`r`n`t)`r`n`r`n`t#Write-Verbose `"Use this cmdlet to deliver information about command processing.`"`r`n`r`n`t#Write-Debug `"Use this cmdlet to write debug information while troubleshooting.`"`r`n`r`n`t#Include this line if the resource requires a system reboot.`r`n`t#`$global:DSCMachineStatus = 1`r`n`r`n`r`n`t<#`r`n`t`$result = [System.Boolean]`r`n`t`r`n`t`$result`r`n`t#>`r`n}`r`n`r`n"

                It 'should return the default function data' {
                    $result | Should Be $expected
                }
            }
        }

        Describe 'New-DscModuleParameter' {
            $dscProperty = [DscResourceProperty] @{
                Name                     = 'Ensure'
                Type                     = 'String'
                Attribute                = [DscResourcePropertyAttribute]::Key
                ValueMap                 = @('Present', 'Absent')
                Values                   = 'Present'
                Description              = 'Ensure Present or Absent'
                ContainsEmbeddedInstance = $false
            }

            Context 'Last Parameter not passed' {
                $result = New-DscModuleParameter $dscProperty[0]
                $expected = "`t`t[parameter(Mandatory = `$true)]`r`n`t`t[ValidateSet(`"Present`",`"Absent`")]`r`n`t`t[System.String]`r`n`t`t`$Ensure,`r`n"

                It 'should return the correct string' {
                    $result | should be $expected
                }
            }

            Context 'Last Parameter is passed' {
                $result = New-DscModuleParameter $dscProperty[0] -Last
                $expected = $expected = "`t`t[parameter(Mandatory = `$true)]`r`n`t`t[ValidateSet(`"Present`",`"Absent`")]`r`n`t`t[System.String]`r`n`t`t`$Ensure"

                It 'should return the string without a comma' {
                    $result | should be $expected
                }
            }
        }

        Describe 'New-DscModuleReturn' {
            $dscProperty = [DscResourceProperty] @{
                Name                     = 'Ensure'
                Type                     = 'String'
                Attribute                = [DscResourcePropertyAttribute]::Key
                ValueMap                 = @('Present', 'Absent')
                Description              = 'Ensure Present or Absent'
                ContainsEmbeddedInstance = $false
            }

            $result = New-DscModuleReturn -Parameters $dscProperty
            $expected = "`t<#`r`n`t`$returnValue = @{`r`n`t`tEnsure = [System.String]`r`n`t}`r`n`r`n`t`$returnValue`r`n`t#>"

            It 'return the correct string' {
                $result | should be $expected
            }
        }

        Describe 'Get-FunctionParamLineNumbers' {
            Context 'Function Name is found in Module'{
                # This might be an awful idea.
                $path = Resolve-Path $PSScriptRoot\cDscResourceDesigner.psm1 | ForEach-Object {$_.Path}

                $functionNames = 'New-cDscResourceProperty'

                $expected = @{
                    'New-cDscResourceProperty' = 308,356,398
                }

                $result = Get-FunctionParamLineNumbers -ModulePath $path -FunctionNames $functionNames

                $testResult =  Compare-Object -ReferenceObject $result -DifferenceObject $expected -PassThru

                It 'Should return the correct array' {
                    $testResult | should BeNullOrEmpty
                }
            }

            Context 'Function Name is NOT found in Module' {
                $path = Resolve-Path $PSScriptRoot\cDscResourceDesigner.psm1 | ForEach-Object {$_.Path}

                $functionNames = 'none'

                $result = Get-FunctionParamLineNumbers -ModulePath $path -FunctionNames $functionNames

                It 'Should return nothing' {
                    $testResult | should BeNullOrEmpty
                }
            }

            # TODO: Not sure how to generate errors in [System.Management.Automation.Language.Parser]
            # Context 'Error Processing Module' {
            # }
        }

        Describe 'Convert-LineNumberToIndex' {
            $result = Convert-LineNumberToIndex -LineNumber 1
            $expect = 0

            It 'Should return the correct number' {
                $result | should be $expect
            }
        }

        Describe 'Get-SortedFunctionNames' {
            $hash = @{
                'New-cDscResourceProperty' = 356,398,308
                'Get-Properties' = 100,398,308
            }
            $result = Get-SortedFunctionNames -functionLineNumbers $hash
            $expect = @('Get-Properties', 'New-cDscResourceProperty')

            It 'Should return the correct hash' {
                $result | should Be $expect
            }
        }
    }
# >>>>>>> parent of d107c61... Adding Test-ResourcePath
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