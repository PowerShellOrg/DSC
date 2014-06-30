$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.ps1", ".psm1")
$pathtosut = join-path $here $sut

iex ( gc $pathtosut -Raw )

Describe 'how Get-TargetResource reponds' {
    Context 'when automatic page file is configured' {
        mock -commandName Get-WmiObject -parameterFilter {$Class -like 'Win32_ComputerSystem'} -mockWith {
            return ([pscustomobject]@{AutomaticManagedPageFile = $true})
        }
        mock -commandName Get-WmiObject -parameterFilter {$Class -like 'Win32_PageFileSetting'} -mockWith {}
        
        $result = Get-TargetResource -initialsize 4GB -MaximumSize 4GB -Ensure 'Present'

        It 'should call once Get-WmiObject Win32_ComputerSystem ' {
            Assert-MockCalled -commandName Get-WmiObject -times 1 -Exactly -parameterFilter {
                $Class -like 'Win32_ComputerSystem'
            }
        }
        It 'should not call Get-WmiObject Win32_PageFileSetting' {
            Assert-MockCalled -commandName Get-WmiObject -times 0 -Exactly -parameterFilter {
                $Class -like 'Win32_PageFileSetting'
            }
        }
        It "should return Ensure = 'Absent'" {
            $result['Ensure'] | should be ('Absent')
        }
    }
    Context 'when automatic page file not configured' {
        mock -commandName Get-WmiObject -parameterFilter {$Class -like 'Win32_ComputerSystem'} -mockWith {
            return ([pscustomobject]@{AutomaticManagedPageFile = $false})
        }
        mock -commandName Get-WmiObject -parameterFilter {$Class -like 'Win32_PageFileSetting'} -mockWith {
            return ([pscustomobject]@{
                                        InitialSize = (3GB/1MB)
                                        MaximumSize = (3GB/1MB)
                                    })
        }
        
        $result = Get-TargetResource -initialsize 4GB -MaximumSize 4GB -Ensure 'Present'

        It 'should call once Get-WmiObject Win32_ComputerSystem ' {
            Assert-MockCalled -commandName Get-WmiObject -times 1 -Exactly -parameterFilter {
                $Class -like 'Win32_ComputerSystem'
            }
        }
        It 'should call once Get-WmiObject Win32_PageFileSetting' {
            Assert-MockCalled -commandName Get-WmiObject -times 1 -Exactly -parameterFilter {
                $Class -like 'Win32_PageFileSetting'
            }
        }
        It "should return Ensure = 'Present' with Intial and Maximum size at 3GB" {
            $result['Ensure'] | should be ('Present')
            $result['InitialSize'] | should be (3GB)
            $result['MaximumSize'] | should be (3GB)
        }

    }
}

Describe 'how Set-TargetResource responds' {

    Context 'when Ensure is set to Absent and AutomaticPageFile is set' {   
        Mock -commandName Get-WmiObject -parameterFilter {$Class -like 'Win32_ComputerSystem'} -mockWith {
            $r = [pscustomobject]@{
                AutomaticManagedPageFile = $true
            } | Add-Member -MemberType ScriptMethod -Name Put -Value {                                    
                    $global:PutWasCalled = $true  
                    $global:PutValue = $this                
            } -PassThru
            return ($r)
        }  
        $global:PutValue = $null   
        $global:PutWasCalled = $False
        Set-TargetResource -initialsize 4GB -MaximumSize 4GB -Ensure 'Absent'
                
        It 'should not call put' {
            $global:PutWasCalled | should be ($false)
        }        
    }
    
    Context 'when Ensure is set to Absent and AutomaticPageFile is not set' {   
        Mock -commandName Get-WmiObject -parameterFilter {$Class -like 'Win32_ComputerSystem'} -mockWith {
            $r = [pscustomobject]@{
                AutomaticManagedPageFile = $false
            } | Add-Member -MemberType ScriptMethod -Name Put -Value {                                    
                    $global:PutWasCalled = $true
                    $global:PutValue = $this                
            } -PassThru
            return ($r)
        }     
        $global:PutValue = $null
        $global:PutWasCalled = $False
        Set-TargetResource -initialsize 4GB -MaximumSize 4GB -Ensure 'Absent'
                
        It 'should call put' {
            $global:PutWasCalled | should be ($true)
        }
        It 'should set AutomaticManagedPageFile set to $true' {
            $global:PutValue.AutomaticManagedPageFile | should be ($true)
        }        
          
    }
    Context 'when Ensure is set to Absent and AutomaticPageFile is not set' {   
        Mock -commandName Get-WmiObject -parameterFilter {$Class -like 'Win32_ComputerSystem'} -mockWith {
            $r = [pscustomobject]@{ AutomaticManagedPageFile = $false 
            } |
                 Add-Member -MemberType ScriptMethod -Name Put -Value {                                    
                    $global:Win32_ComputerPutWasCalled = $true
                    $global:Win32_ComputerPutValue = $this                
                } -PassThru
            return ($r)
        }        
        Mock -commandName Get-WmiObject -parameterFilter {$Class -like 'Win32_PageFileSetting'} -mockWith {
            $r = [pscustomobject]@{
                InitialSize = 0 
                MaximumSize = 0 
            } | Add-Member -MemberType ScriptMethod -Name Put -Value {                                    
                    $global:Win32_PageFileSettingPutWasCalled = $true
                    $global:Win32_PageFileSettingPutValue = $this                
            } -PassThru
            return ($r)
        }
             
        $global:Win32_ComputerPutValue = $null
        $global:Win32_ComputerPutWasCalled = $False
        $global:Win32_PageFileSettingPutValue = $null
        $global:Win32_PageFileSettingPutWasCalled = $False

        Set-TargetResource -initialsize 4GB -MaximumSize 4GB -Ensure 'Absent'
                
        It 'should call put to Win32_ComputerSystem' {
            $global:Win32_ComputerPutWasCalled | should be ($true)
        }
        It 'should set AutomaticManagedPageFile set to $true' {
            $global:Win32_ComputerPutValue.AutomaticManagedPageFile | should be ($true)
        }        
          
    }
    Context 'when Ensure is set to Present and AutomaticPageFile is not set' {   
        Mock -commandName Get-WmiObject -parameterFilter {$Class -like 'Win32_ComputerSystem'} -mockWith {
            $r = [pscustomobject]@{ AutomaticManagedPageFile = $false 
            } |
                 Add-Member -MemberType ScriptMethod -Name Put -Value {                                    
                    $global:Win32_ComputerPutWasCalled = $true
                    $global:PutVWin32_ComputerPutValuealue = $this                
                } -PassThru
            return ($r)
        }        
        Mock -commandName Get-WmiObject -parameterFilter {$Class -like 'Win32_PageFileSetting'} -mockWith {
            $r = [pscustomobject]@{
                InitialSize = 0 
                MaximumSize = 0 
            } | Add-Member -MemberType ScriptMethod -Name Put -Value {                                    
                    $global:Win32_PageFileSettingPutWasCalled = $true
                    $global:Win32_PageFileSettingPutValue = $this                
            } -PassThru
            return ($r)
        }
             
        $global:Win32_ComputerPutValue = $null
        $global:Win32_ComputerPutWasCalled = $False
        $global:Win32_PageFileSettingPutValue = $null
        $global:Win32_PageFileSettingPutWasCalled = $False

        Set-TargetResource -initialsize 4GB -MaximumSize 4GB -Ensure 'Present'
                
        It 'should call put on Win32_PageFileSetting' {
            $global:PutWasCalled | should be ($true)
        }
        It 'should not set AutomaticManagedPageFile set to $true' {
            $global:Win32_ComputerPutValue.AutomaticManagedPageFile | should beNullOrEmpty
        }        
        It 'should set Initial and Maximum size to 4 GB' {
            $global:Win32_PageFileSettingPutValue.InitialSize | should be (4gb/1mb)
            $global:Win32_PageFileSettingPutValue.MaximumSize | should be (4gb/1mb)
        }        
          
    }


    Get-Variable -Scope Global -Name Win32_ComputerPutValue | 
        Remove-Variable -Scope Global -Force
    Get-Variable -Scope Global -Name Win32_ComputerPutWasCalled | 
        Remove-Variable -Scope Global -Force
    Get-Variable -Scope Global -Name Win32_PageFileSettingPutValue | 
        Remove-Variable -Scope Global -Force
    Get-Variable -Scope Global -Name Win32_PageFileSettingPutWasCalled | 
        Remove-Variable -Scope Global -Force
}


