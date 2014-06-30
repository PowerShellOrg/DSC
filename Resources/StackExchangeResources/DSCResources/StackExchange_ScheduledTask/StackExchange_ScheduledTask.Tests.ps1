$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.ps1", ".psm1")
$pathtosut = join-path $here $sut

iex (gc $pathtosut -Raw)

Describe 'how Test-JobFilePath responds' {
    Context 'when the file path is correct' {
        $script:TargetResource = [pscustomobject]@{
            FilePath = 'c:\scripts\test.ps1'
            Job = [pscustomobject]@{
                Command = 'c:\scripts\test.ps1'
            }
            IsValid = $true
        }

        Test-JobFilePath
        it 'should return true' {
            $script:TargetResource.IsValid | should be $true
        }
    }

    Context 'when the file path is correct' {
        $script:TargetResource = [pscustomobject]@{
            FilePath = 'c:\scripts\test.ps1'
            Job = [pscustomobject]@{
                Command = 'c:\scripts\nottest.ps1 '
            }
            IsValid = $true
        }

        Test-JobFilePath
        it 'should return false' {
            $script:TargetResource.IsValid | should be $false
        }
    }
}

Describe 'how Test-JobTriggerAtTime responds' { 
    Context 'when job At time matches configured At time' {
        $script:TargetResource = [pscustomobject]@{
            At = '1/1/2014'            
            Job = [pscustomobject]@{
                JobTriggers = @(
                    [pscustomobject]@{
                        At = [pscustomobject]@{
                            Value = [datetime]::Parse('1/1/2014')
                            HasValue = $true
                        }
                    }
                )
            }
            IsValid = $true
        }
        
        Test-JobTriggerAtTime
        
        It 'should return true ' {
            $script:TargetResource.IsValid | should be ($true)
        }
    }

    Context 'when job At time does not match configured At time' {
        $script:TargetResource = [pscustomobject]@{
            At = '1/1/2014'            
            Job = [pscustomobject]@{
                JobTriggers = @(
                    [pscustomobject]@{
                        At = [pscustomobject]@{
                            Value = [datetime]::Parse('2/1/2014')
                            HasValue = $true
                        }
                    }
                )
            }
            IsValid = $true
        }
        
        Test-JobTriggerAtTime
        
        It 'should return false ' {
            $script:TargetResource.IsValid | should be ($false)
        }
    }
}

Describe 'how Test-JobFrequency responds' {
    context 'when job frequency is once and the requested frequency is once' {
        $script:TargetResource = [pscustomobject]@{
            Once = $true
            Job = [pscustomobject]@{
                JobTriggers = @(
                    [pscustomobject]@{
                        Frequency = 'once'
                    }
                )
            }
            IsValid = $true
        }
        Test-JobFrequency
        it 'should be true' {
            $script:TargetResource.IsValid | should be $true 
        }
    }

    context 'when job frequency is once and the requested frequency is daily' {
        $script:TargetResource = [pscustomobject]@{
            Daily = $true
            Job = [pscustomobject]@{
                JobTriggers = @(
                    [pscustomobject]@{
                        Frequency = 'once'
                    }
                )
            }
            IsValid = $true
        }
        Test-JobFrequency
        it 'should be false' {
            $script:TargetResource.IsValid | should be $false
        }
    }

    context 'when job frequency is once and the requested frequency is weekly' {
        $script:TargetResource = [pscustomobject]@{
            Weekly = $true
            Job = [pscustomobject]@{
                JobTriggers = @(
                    [pscustomobject]@{
                        Frequency = 'once'
                    }
                )
            }
            IsValid = $true
        }
        Test-JobFrequency
        it 'should be false' {
            $script:TargetResource.IsValid | should be $false
        }
    }

    context 'when job frequency is daily and the requested frequency is once' {
        $script:TargetResource = [pscustomobject]@{
            Once = $true
            Job = [pscustomobject]@{
                JobTriggers = @(
                    [pscustomobject]@{
                        Frequency = 'Daily'
                    }
                )
            }
            IsValid = $true
        }
        Test-JobFrequency
        it 'should be false' {
            $script:TargetResource.IsValid | should be $false 
        }
    }

    context 'when job frequency is daily and the requested frequency is daily' {
        $script:TargetResource = [pscustomobject]@{
            Daily = $true
            Job = [pscustomobject]@{
                JobTriggers = @(
                    [pscustomobject]@{
                        Frequency = 'Daily'
                    }
                )
            }
            IsValid = $true
        }
        Test-JobFrequency
        it 'should be true' {
            $script:TargetResource.IsValid | should be $true
        }
    }

    context 'when job frequency is daily and the requested frequency is weekly' {
        $script:TargetResource = [pscustomobject]@{
            Weekly = $true
            Job = [pscustomobject]@{
                JobTriggers = @(
                    [pscustomobject]@{
                        Frequency = 'Daily'
                    }
                )
            }
            IsValid = $true
        }
        Test-JobFrequency
        it 'should be false' {
            $script:TargetResource.IsValid | should be $false
        }
    }

    context 'when job frequency is weekly and the requested frequency is once' {
        $script:TargetResource = [pscustomobject]@{
            Once = $true
            Job = [pscustomobject]@{
                JobTriggers = @(
                    [pscustomobject]@{
                        Frequency = 'Weekly'
                    }
                )
            }
            IsValid = $true
        }
        Test-JobFrequency
        it 'should be false' {
            $script:TargetResource.IsValid | should be $false 
        }
    }

    context 'when job frequency is weekly and the requested frequency is daily' {
        $script:TargetResource = [pscustomobject]@{
            Daily = $true
            Job = [pscustomobject]@{
                JobTriggers = @(
                    [pscustomobject]@{
                        Frequency = 'Weekly'
                    }
                )
            }
            IsValid = $true
        }
        Test-JobFrequency
        it 'should be false' {
            $script:TargetResource.IsValid | should be $false
        }
    }

    context 'when job frequency is weekly and the requested frequency is weekly' {
        $script:TargetResource = [pscustomobject]@{
            Weekly = $true
            Job = [pscustomobject]@{
                JobTriggers = @(
                    [pscustomobject]@{
                        Frequency = 'Weekly'
                    }
                )
            }
            IsValid = $true
        }
        Test-JobFrequency
        it 'should be true' {
            $script:TargetResource.IsValid | should be $true
        }
    }
}

Describe 'how Test-OnceJobTrigger responds' {

    Context 'when job frequency is Once and set to repeat every hour and a half.' {
        $script:TargetResource = [pscustomobject]@{
            Once = $true
            Hours = 1
            Minutes = 30
            Job = [pscustomobject]@{
                JobTriggers = @(
                    [pscustomobject]@{
                        Frequency = 'Once'
                        RepetitionInterval = [pscustomobject]@{
                            Value = [pscustomobject]@{
                                Hours = 1
                                Minutes = 30
                            }
                            HasValue = $true
                        }
                    }
                )
            }
            IsValid = $true
        }
        
        Test-OnceJobTrigger
        
        It 'should return true' {
            $script:TargetResource.IsValid | should be ($true)
        }
    }

    Context 'when job frequency is Once and set to repeat every hour and a half but should be every two hours' {
        $script:TargetResource = [pscustomobject]@{
            Once = $true
            Hours = 2
            Minutes = 0
            Job = [pscustomobject]@{
                JobTriggers = @(
                    [pscustomobject]@{
                        Frequency = 'Once'
                        RepetitionInterval = [pscustomobject]@{
                            Value = [pscustomobject]@{
                                Hours = 1
                                Minutes = 30
                            }
                            HasValue = $true
                        }
                    }
                )
            }
            IsValid = $true
        }
        
        Test-OnceJobTrigger
        
        It 'should return false' {
            $script:TargetResource.IsValid | should be ($false)
        }
    }

    Context 'when job frequency is Once and repetition interval is null' {
        $script:TargetResource = [pscustomobject]@{
            Once = $true
            Hours = 2
            Minutes = 0
            Job = [pscustomobject]@{
                JobTriggers = @(
                    [pscustomobject]@{
                        Frequency = 'Once'
                        RepetitionInterval = [pscustomobject]@{
                            Value = $null
                            HasValue = $false
                        }
                    }
                )
            }
            IsValid = $true
        }
        
        Test-OnceJobTrigger
        
        It 'should return false' {
            $script:TargetResource.IsValid | should be ($false)
        }
    }
}

Describe 'how Test-DailyJobTrigger responds' {
    Context 'when job frequency is Daily and should have an interval of 1' {
        $script:TargetResource = [pscustomobject]@{
            Daily = $true
            DaysInterval = 1
            Job = [pscustomobject]@{
                JobTriggers = @(
                    [pscustomobject]@{
                        Frequency = 'Daily'
                        Interval = 1
                    }
                )
            }
            IsValid = $true
        }
        
        Test-DailyJobTrigger
        
        It 'should return true ' {
            $script:TargetResource.IsValid | should be ($true)
        }
    }

    Context 'when job frequency is Daily with an interval of 1 and should have an interval of 2' {
        $script:TargetResource = [pscustomobject]@{
            Daily = $true
            DaysInterval = 2
            Job = [pscustomobject]@{
                JobTriggers = @(
                    [pscustomobject]@{
                        Frequency = 'Daily'
                        Interval = 1
                    }
                )
            }
            IsValid = $true
        }
        
        Test-DailyJobTrigger
        
        It 'should return false ' {
            $script:TargetResource.IsValid | should be ($false)
        }
    }
}

Describe 'how Test-WeeklyJobTrigger responds' { 

    Context 'when job frequency is Weekly with days of the week should be Weekly with days of week ' {
        $script:TargetResource = [pscustomobject]@{
            Weekly = $true
            DaysOfWeek = 'Monday', 'Wednesday', 'Friday'
            Job = [pscustomobject]@{
                JobTriggers = @(
                    [pscustomobject]@{
                        Frequency = 'Weekly'
                        DaysOfWeek = 'Monday', 'Wednesday', 'Friday'
                    }
                )
            }
            IsValid = $true
        }

        Test-WeeklyJobTrigger 
        
        It 'should return true ' {
            $script:TargetResource.IsValid | should be ($true)
        }
    }

     Context 'when job frequency is Weekly with days of week, but should be Weekly ' {
        $script:TargetResource = [pscustomobject]@{
            Weekly = $true
            DaysOfWeek = [string[]]@()
            Job = [pscustomobject]@{
                JobTriggers = @(
                    [pscustomobject]@{
                        Frequency = 'Weekly'
                        DaysOfWeek = 'Monday', 'Wednesday', 'Friday'
                    }
                )
            }
            IsValid = $true
        }
        
        Test-WeeklyJobTrigger 
        
        It 'should return false ' {
            $script:TargetResource.IsValid | should be ($false)
        }
    }
}

Describe 'how Test-TargetResource responds' {
    Context 'when the job does not exist ' {
        Mock -commandName Get-ScheduledJob -mockWith {$null}
        
        $result = Test-TargetResource -Name Test -FilePath c:\scripts\test.ps1 -Once $true -Hours 1 -Minutes 1

        It "should call all the mocks" {
            Assert-MockCalled -commandName Get-ScheduledJob -times 1 -Exactly
        }
        It 'should be false' {
            $result | should be ($false)
        }
    }

    Context 'when the job exists but should not ' {
        Mock -commandName Get-ScheduledJob -mockWith {
            return ([pscustomobject]@{                
                FilePath = 'c:\scripts\test2.ps1'
            })
        }
        
        $result = Test-TargetResource -Name Test -FilePath c:\scripts\test.ps1 -Once $true -Hours 1 -Minutes 1 -Ensure Absent

        It "should call Get-ScheduledJob" {
            Assert-MockCalled -commandName Get-ScheduledJob -times 1 -Exactly
        }
        It 'should be false' {
            $result | should be ($false)
        }
    }

    Context 'when the job exists, but the file path is wrong ' {
        Mock -commandName Get-ScheduledJob -mockWith {
            return ([pscustomobject]@{                
                Command = 'c:\scripts\test.ps1'                
                JobTriggers = ,([pscustomobject]@{
                    Frequency = 'Once'
                    RepetitionInterval = [pscustomobject]@{
                        Value = [pscustomobject]@{
                            Hours = 1
                            Minutes = 30
                        }
                        HasValue = $true
                    }
                })             
            })
        }   

        $result = Test-TargetResource -Name Test -FilePath c:\scripts\test.ps1 -Once $true -Hours 1 -Minutes 1

        It 'should be false ' {
            $result | should be ($false)
        }
    }
    
    Context 'when the job exits exist, and is configured to repeat every hour and a half ' {

        Mock -commandName Get-ScheduledJob -mockWith {
            return ([pscustomobject]@{                
                Command = 'c:\scripts\test.ps1'                
                JobTriggers = ,([pscustomobject]@{
                    Frequency = 'Once'
                    RepetitionInterval = [pscustomobject]@{
                        Value = [pscustomobject]@{
                            Hours = 1
                            Minutes = 30
                        }
                        HasValue = $true
                    }
                })             
            })
        }

        $result = Test-TargetResource -Name Test -FilePath c:\scripts\test.ps1 -Once $true -Hours 1 -Minutes 30 -At '1/1/2014'

        It 'should be true ' {
            $result | should be ($true)
        }
    }

    Context 'when the job exists, and is configured to repeat every hour and a half ' {

        Mock -commandName Get-ScheduledJob -mockWith {
            return ([pscustomobject]@{                
                Command = 'c:\scripts\test.ps1'                
                JobTriggers = ,([pscustomobject]@{
                    Frequency = 'Once'
                    RepetitionInterval = [pscustomobject]@{
                        Value = [pscustomobject]@{
                            Hours = 1
                            Minutes = 30
                        }
                        HasValue = $true
                    }
                })             
            })
        }

        $result = Test-TargetResource -Name Test -FilePath c:\scripts\test.ps1 -Once $true -Hours 1 -Minutes 30 -At '1/1/2014'

        It 'should be true ' {
            $result | should be ($true)
        }
    }

    Context 'when the job exists, and is configured to repeat every hour and a half but should be weekly ' {

        Mock -commandName Get-ScheduledJob -mockWith {
            return ([pscustomobject]@{                
                Command = 'c:\scripts\test.ps1'                
                JobTriggers = ,([pscustomobject]@{
                    Frequency = 'Once'
                    RepetitionInterval = [pscustomobject]@{
                        Value = [pscustomobject]@{
                            Hours = 1
                            Minutes = 30
                        }
                        HasValue = $true
                    }
                })             
            })
        }

        $result = Test-TargetResource -Name Test -FilePath c:\scripts\test.ps1 -weekly $true
        It 'should be false ' {
            $result | should be ($false)
        }
    }

    Context 'when the job exists, but should not ' {
        Mock -commandName Get-ScheduledJob -mockWith {
            return ([pscustomobject]@{                
                Command = 'c:\scripts\test.ps1'                
                JobTriggers = ,([pscustomobject]@{
                    Frequency = 'Once'
                    RepetitionInterval = [pscustomobject]@{
                        Value = [pscustomobject]@{
                            Hours = 1
                            Minutes = 30
                        }
                        HasValue = $true
                    }
                })             
            })
        }

        $result = Test-TargetResource -Name Test -FilePath c:\scripts\test.ps1 -Ensure Absent

        It 'should be false ' {
            $result | should be ($false)
        }
    }
}

<#
Describe 'how Set-TargetResource responds' {
    Context 'when ' {
        $expected = ''
        $result = ''

        It "should call all the mocks" {
            Assert-VerifiableMocks
        }
        It 'should ' {
            $result | should be ($expected)
        }

    }
}


#>
