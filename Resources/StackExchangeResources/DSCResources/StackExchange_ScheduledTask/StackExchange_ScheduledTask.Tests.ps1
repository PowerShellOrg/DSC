$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.ps1", ".psm1")
$pathtosut = join-path $here $sut

iex (gc $pathtosut -Raw)

Describe 'how Test-TargetResource responds' {
    Context 'when the job does not exist ' {
        Mock -commandName Get-ScheduledJob -mockWith {}
        
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

    Context 'when the job exits exist, but the file path is wrong ' {
        Mock -commandName Test-JobTriggerAtTime -mockWith {return $true}
        Mock -commandName Test-OnceJobTrigger -mockWith {return $true}
        Mock -commandName Test-DailyJobTrigger -mockWith {return $true}
        Mock -commandName Test-WeeklyJobTrigger -mockWith {return $true}
        Mock -commandName Get-ScheduledJob -mockWith {
            return ([pscustomobject]@{                
                FilePath = 'c:\scripts\test2.ps1'
            })
        }

        $result = Test-TargetResource -Name Test -FilePath c:\scripts\test.ps1 -Once $true -Hours 1 -Minutes 1

        It 'should be false ' {
            $result | should be ($false)
        }
    }
    
    Context 'when the job exits exist, and is configured to repeat every hour and a half ' {
        Mock -commandName Test-JobTriggerAtTime -mockWith {return $true}
        Mock -commandName Test-OnceJobTrigger -mockWith {return $true}
        Mock -commandName Test-DailyJobTrigger -mockWith {return $true}
        Mock -commandName Test-WeeklyJobTrigger -mockWith {return $true}
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

        It 'should call Test-OnceJobTrigger with the proper parameters' {
            Assert-MockCalled -commandName Test-OnceJobTrigger -times 1 -Exactly -parameterFilter {
                ($Hours -eq 1) -and ($Minutes -eq 30) -and ($Once) -and ($Trigger -ne $null)
            }
        }

        It 'should be true ' {
            $result | should be ($true)
        }
    }

    Context 'when the job exists, and is configured to repeat every hour and a half ' {
        Mock -commandName Test-JobTriggerAtTime -mockWith {return $true}
        Mock -commandName Test-OnceJobTrigger -mockWith {return $true}
        Mock -commandName Test-DailyJobTrigger -mockWith {return $true}
        Mock -commandName Test-WeeklyJobTrigger -mockWith {return $true}
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

        It 'should call Test-OnceJobTrigger with the proper parameters' {
            Assert-MockCalled -commandName Test-OnceJobTrigger -times 1 -Exactly -parameterFilter {
                ($Hours -eq 1) -and ($Minutes -eq 30) -and ($Once) -and ($Trigger -ne $null)
            }
        }

        It 'should be true ' {
            $result | should be ($true)
        }
    }

    Context 'when the job exists, and is configured to repeat every hour and a half but should be weekly ' {
        Mock -commandName Test-JobTriggerAtTime -mockWith {return $true}
        Mock -commandName Test-OnceJobTrigger -mockWith {return $true}
        Mock -commandName Test-DailyJobTrigger -mockWith {return $true}
        Mock -commandName Test-WeeklyJobTrigger -mockWith {return $false}
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

        It 'should call Test-OnceJobTrigger with the proper parameters' {
            Assert-MockCalled -commandName Test-OnceJobTrigger -times 1 -Exactly -parameterFilter {
                ($Hours -eq 0) -and ($Minutes -eq 0) -and (-not $Once) -and ($Trigger -ne $null)
            }
        }
        It 'should call Test-WeeklyJobTrigger with the proper parameters' {
            Assert-MockCalled -commandName Test-WeeklyJobTrigger -times 1 -Exactly -parameterFilter {
                 ($Weekly) -and ($Trigger -ne $null)
            }
        }

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

Describe 'how Test-OnceJobTrigger responds' {

    Context 'when job frequency is Once and set to repeat every hour and a half.' {
        $trigger = [pscustomobject]@{
            Frequency = 'Once'
            RepetitionInterval = [pscustomobject]@{
                Value = [pscustomobject]@{
                    Hours = 1
                    Minutes = 30
                }
                HasValue = $true
            }
        }
        
        $result = Test-OnceJobTrigger -Trigger $trigger -Hours 1 -Minutes 30 -Once $true
        
        It 'should return true' {
            $result | should be ($true)
        }
    }

    Context 'when job frequency is Once and set to repeat every hour and a half but should be every two hours' {
        $trigger = [pscustomobject]@{
            Frequency = 'Once'
            RepetitionInterval = [pscustomobject]@{
                Value = [pscustomobject]@{
                    Hours = 1
                    Minutes = 30
                }
                HasValue = $true
            }
        }
        
        $result = Test-OnceJobTrigger -Trigger $trigger -Hours 2 -Minutes 0 -Once $true
        
        It 'should return false ' {
            $result | should be ($false)
        }
    }

    Context 'when job frequency is Once and repetition interval is null' {
        $trigger = [pscustomobject]@{
            Frequency = 'Once'
            RepetitionInterval = [pscustomobject]@{                
                HasValue = $false
            }
        }
        
        $result = Test-OnceJobTrigger -Trigger $trigger -Hours 2 -Minutes 0 -Once $true
        
        It 'should return false ' {
            $result | should be ($false)
        }
    }

    Context 'when job frequency is Weekly and should be Once' {
        $trigger = [pscustomobject]@{
            Frequency = 'Weekly'
            RepetitionInterval = [pscustomobject]@{                
                HasValue = $false
            }
        }
        
        $result = Test-OnceJobTrigger -Trigger $trigger -Hours 2 -Minutes 0 -Once $true
        
        It 'should return false ' {
            $result | should be ($false)
        }
    }
}

Describe 'how Test-DailyJobTrigger responds' {    

    Context 'when job frequency is Daily and should have an interval of 1' {
        $trigger = [pscustomobject]@{
            Frequency = 'Daily'
            Interval = 1
        }
        
        $result = Test-DailyJobTrigger -Trigger $trigger -DaysInterval 1 -Daily $true
        
        It 'should return true ' {
            $result | should be ($true)
        }
    }

    Context 'when job frequency is Daily with an interval of 1 and should have an interval of 2' {
        $trigger = [pscustomobject]@{
            Frequency = 'Daily'
            Interval = 1
        }
        
        $result = Test-DailyJobTrigger -Trigger $trigger -DaysInterval 2 -Daily $true
        
        It 'should return false ' {
            $result | should be ($false)
        }
    }

    Context 'when job frequency is Once should be Daily' {
        $trigger = [pscustomobject]@{
            Frequency = 'Once'
            Interval = 0
            RepetitionInterval = [pscustomobject]@{
                Value = [pscustomobject]@{
                    Hours = 1
                    Minutes = 30
                }
                HasValue = $true
            }
        }
        
        $result = Test-DailyJobTrigger -Trigger $trigger -DaysInterval 1 -Daily $true
        
        It 'should return false ' {
            $result | should be ($false)
        }
    }
}

Describe 'how Test-JobTriggerAtTime responds' { 
    Context 'when job At time matches configured At time' {
        $trigger = [pscustomobject]@{
            At = [pscustomobject]@{
                Value = [datetime]::Parse('1/1/2014')
                HasValue = $true
            }
        }
        
        $result = Test-JobTriggerAtTime -Trigger $trigger -At '1/1/2014'
        
        It 'should return true ' {
            $result | should be ($true)
        }
    }

    Context 'when job At time does not match configured At time' {
        $trigger = [pscustomobject]@{
            At = [pscustomobject]@{
                Value = [datetime]'1/2/2014'
                HasValue = $true
            }
        }
        
        $result = Test-JobTriggerAtTime -Trigger $trigger -At '1/1/2014'
        
        It 'should return false ' {
            $result | should be ($false)
        }
    }
}

Describe 'how Test-WeeklyJobTrigger responds' { 

    Context 'when job frequency is Weekly with days fo the week should be Weekly with days of week ' {
        $trigger = [pscustomobject]@{
            Frequency = 'Weekly'
            DaysOfWeek = 'Monday', 'Wednesday', 'Friday'
        }
        
        $result = Test-WeeklyJobTrigger -Trigger $trigger -DaysOfWeek 'Monday', 'Wednesday', 'Friday' -Weekly $true
        
        It 'should return true ' {
            $result | should be ($true)
        }
    }

    Context 'when job frequency is Weekly should be Weekly ' {
        $trigger = [pscustomobject]@{
            Frequency = 'Weekly'
            DaysOfWeek = @()
        }
        
        $result = Test-WeeklyJobTrigger -Trigger $trigger  -Weekly $true
        
        It 'should return true ' {
            $result | should be ($true)
        }
    }

     Context 'when job frequency is Weekly with days of week, but should be Weekly ' {
        $trigger = [pscustomobject]@{
            Frequency = 'Weekly'
            DaysOfWeek = 'Monday', 'Wednesday', 'Friday'
        }
        
        $result = Test-WeeklyJobTrigger -Trigger $trigger -Weekly $true
        
        It 'should return false ' {
            $result | should be ($false)
        }
    }

    Context 'when job frequency is Daily, but should be Weekly ' {
        $trigger = [pscustomobject]@{
            Frequency = 'Daily'
            Interval = 1
        }
        
        $result = Test-WeeklyJobTrigger -Trigger $trigger -Weekly $true
        
        It 'should return false ' {
            $result | should be ($false)
        }
    }

    Context 'when job frequency is Daily, but should be Daily ' {
        $trigger = [pscustomobject]@{
            Frequency = 'Daily'
            Interval = 1
        }
        
        $result = Test-WeeklyJobTrigger -Trigger $trigger -Weekly $false
        
        It 'should return true ' {
            $result | should be ($true)
        }
    }

}
