Import-Module .\cDscDiagnostics.psm1

Describe "Trace-cDscOperation" {
    Context "does it call its internal functions" {
        Mock -ModuleName cDscDiagnostics Add-ClassTypes {}
        Mock -ModuleName cDscDiagnostics Trace-DscOperationInternal {}
        Mock -ModuleName cDscDiagnostics Log {}

        $result = Trace-cDscOperation -ComputerName $env:ComputerName;

        It "should call Add-ClassType" {
            Assert-MockCalled Add-ClassTypes -ModuleName cDscDiagnostics -Times 1
        }

        It "should call Trace-DscOperationInternal" {
            Assert-MockCalled Trace-DscOperationInternal -ModuleName cDscDiagnostics -Times 1
        }

        It "should call Log" {
            Assert-MockCalled Log -ModuleName cDscDiagnostics -Times 1
        }
    }
}

Describe "Add-ClassTypes" {
    Context "when its called" {
        Mock -ModuleName cDscDiagnostics Update-FormatData {}
        Mock -ModuleName cDscDiagnostics Trace-DscOperationInternal {}
        Mock -ModuleName cDscDiagnostics Log {}

        $result = Trace-cDscOperation -ComputerName $env:ComputerName;

        It "should have loaded it's event types" {
            { [Microsoft.PowerShell.cDscDiagnostics.EventType]::ANALYTIC } | Should Not Throw
        }

        It "should have loaded it's group events" {
            { [Microsoft.PowerShell.cDscDiagnostics.GroupedEvents] } | Should Not Throw
        }
    }
}

InModuleScope cDscDiagnostics {
    Describe 'Log' {
        It 'Should write verbosely' {
            $text = "Verbose Text"
            $verboseLog = Log $text -Verbose 4>&1
            $verboseLog | Should Be $text
        }

        It 'should write errors' {
            $text = "Error Text"
            $errorLog = Log $text -Error 2>&1
            $errorLog | Should Be $text
        }

        BeforeEach {
            $vPreference = $VerbosePreference;
            $ePreference = $ErrorAction;

            $VerbosePreference = "Continue";
            $ErrorAction = "Continue";
        }

        AfterEach {
            $VerbosePreference = $vPreference;
            $ErrorAction = $ePreference;
        }
    }

    Describe 'Trace-DscOperationInternal' {
        Context 'SequenceID is passed' {
            Mock -ModuleName cDscDiagnostics Log { }
            $result = Trace-DscOperationInternal -SequenceID 0;

            It 'should return null if SequenceID is less then 1' {
                $result | Should Be $null;
            }

            $date = Get-Date;
            $message = "Some Message";
            # Choosing Application because we need /something/ here and we can't assume that the machine has run a DSC command.
            $event = Get-WinEvent -LogName Application -MaxEvents 1

            $traceOutput = New-Object PSObject -Property @{
                Type = "Operational";
                TimeCreated = $date;
                Message = $message;
                ComputerName = $env:ComputerName;
                SequenceID = 2;
                Event = $event;
            }

            Mock -ModuleName cDscDiagnostics Get-SingleDscOperation { return @{
                    AllEvents = $traceOutput;
                    ErrorEvents = "SomeEvent";
                    JobId = "54137c5a-f607-48a5-9311-d6e102c15f83";
                }
            }

            Mock -ModuleName cDscDiagnostics Test-DscEventLogStatus { }
            Mock -ModuleName cDscDiagnostics Get-DscErrorMessage { return "Error Text" }

            $result = Trace-DscOperationInternal -SequenceID 2;

            It 'should do call Test-DscEventLogStatus' {
                Assert-MockCalled Test-DscEventLogStatus -ModuleName cDscDiagnostics -Times 2
            }

            It 'should call Get-SingleDscOperation' {
                Assert-MockCalled Get-SingleDscOperation -ModuleName cDscDiagnostics -Times 1
            }

            It 'should call Get-DscErrorMessage' {
                Assert-MockCalled Get-DscErrorMessage -ModuleName cDscDiagnostics -Times 1
            }

            It 'should return the correct event type' {
                $result.EventType | Should Be "Operational";
            }

            It 'should return the correct time' {
                $result.TimeCreated | Should Be $date;
            }

            It 'should return the correct message' {
                $result.Message | Should Be $message;
            }

            It 'should return the correct machine' {
                $result.ComputerName | Should Be $env:ComputerName;
            }

            It 'should return the correct SequenceID' {
                $result.SequenceID | Should Be 2;
            }

            It 'should return the correct Event' {
                $result.Event | Should Be $event;
            }
        }

        Context 'JobId Passed' {
            $date = Get-Date;
            $message = "Some Message";
            # Choosing Application because we need /something/ here and we can't assume that the machine has run a DSC command.
            $event = Get-WinEvent -LogName Application -MaxEvents 1

            $traceOutput = New-Object PSObject -Property @{
                Type = "Operational";
                TimeCreated = $date;
                Message = $message;
                ComputerName = $env:ComputerName;
                SequenceID = 1;
                Event = $event;
            }

            Mock -ModuleName cDscDiagnostics Get-SingleDscOperation { return @{
                    AllEvents = $traceOutput;
                    ErrorEvents = "SomeEvent";
                    JobId = "54137c5a-f607-48a5-9311-d6e102c15f83";
                }
            }

            Mock -ModuleName cDscDiagnostics Test-DscEventLogStatus { }
            Mock -ModuleName cDscDiagnostics Get-DscErrorMessage { return "Error Text" }

            $result = Trace-DscOperationInternal -SequenceID 1 -JobId "54137c5a-f607-48a5-9311-d6e102c15f83";

            It 'should return the Job Id' {
                $result.JobId | Should Be "54137c5a-f607-48a5-9311-d6e102c15f83"
            }
        }

        Context 'Get-SingleDscOperation returns null' {
            Mock -ModuleName cDscDiagnostics Test-DscEventLogStatus { }
            Mock -ModuleName cDscDiagnostics Get-SingleDscOperation { }

            $result = Trace-DscOperationInternal -SequenceID 1 -JobId "54137c5a-f607-48a5-9311-d6e102c15f83";

            It 'should return null' {
                $result | Should Be $null;
            }
        }

        # This way we don't cache anything while testing.
        AfterEach {
            Clear-DscDiagnosticsCache
        }
    }

    Describe 'Get-DscLatestJobId' {
        Context 'It has a Job to Return' {
            Mock -ModuleName cDscDiagnostics Get-WinEvent {
                $value = @{"Value" = "{3BBB79B7-BD46-424C-9718-983C8C76D37E}"}
                $returnObject = @(@{Properties = @($value)}, [Environment]::NewLine)
                return @(@{Properties = @($value)}, [Environment]::NewLine)
            }

            $result = Get-DscLatestJobId;

            It 'should return the GUID' {
                $result | Should Be "{3BBB79B7-BD46-424C-9718-983C8C76D37E}"
            }
        }

        Context 'When it does not have a Job' {
            Mock -ModuleName cDscDiagnostics Get-WinEvent {
                return $null
            }

            $result = Get-DscLatestJobId;

            It 'should return "NOJOBID"' {
                $result | Should Be "NOJOBID"
            }
        }

        AfterEach {
            Clear-DscDiagnosticsCache
        }
    }
}

Describe "Get-cDscOperation" {
    Context "does it call its internal functions" {
        Mock -ModuleName cDscDiagnostics Add-ClassTypes {}
        Mock -ModuleName cDscDiagnostics Get-DscOperationInternal {}
        Mock -ModuleName cDscDiagnostics Log {}

        $result = Get-cDscOperation -ComputerName $env:ComputerName;

        It "should call Add-ClassType" {
            Assert-MockCalled Add-ClassTypes -ModuleName cDscDiagnostics -Times 1
        }

        It "should call Get-DscOperationInternal" {
            Assert-MockCalled Get-DscOperationInternal -ModuleName cDscDiagnostics -Times 1
        }

        It "should call Log" {
            Assert-MockCalled Log -ModuleName cDscDiagnostics -Times 1
        }
    }
}